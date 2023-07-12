#define ASIO_STANDALONE

#include <csignal>
#include <iostream>
#include <set>
#include <nlohmann/json.hpp>
#include <websocketpp/config/asio_no_tls.hpp>
#include <websocketpp/server.hpp>
#include "spdlog/spdlog.h"
#include "vlcpp/vlc.hpp"
#include "server.hpp"

using JSON = nlohmann::json;
using WebsocketServer = websocketpp::server<websocketpp::config::asio>;

class PlayerServerPrivate {
public:
  PlayerServerPrivate(uint16_t port, int vlc_argc, const char **vlc_argv) {
    // Initialize the websocket server
    m_server.init_asio();
    m_server.clear_access_channels(websocketpp::log::alevel::all);

    // Set event handlers
    m_server.set_open_handler(bind(&PlayerServerPrivate::on_open, this, std::placeholders::_1));
    m_server.set_close_handler(bind(&PlayerServerPrivate::on_close, this, std::placeholders::_1));
    m_server.set_message_handler(bind(&PlayerServerPrivate::on_message, this, std::placeholders::_1, std::placeholders::_2));

    // Set the port
    m_port = port;

    // Create a VLC instance
    m_vlc_instance = VLC::Instance(vlc_argc, vlc_argv);
    m_vlc_instance.setAppId(APP_NAME, APP_VERSION, "speaker");
    m_vlc_instance.setUserAgent(APP_USER_AGENT, APP_USER_AGENT);

    // Create a media player
    m_media_player = VLC::MediaPlayer(m_vlc_instance);
    m_media_list_player = VLC::MediaListPlayer(m_vlc_instance);

    m_media_list_player.setMediaPlayer(m_media_player);

    auto event_manager = m_media_player.eventManager();

    // Bind VLC events
    event_manager.onMediaChanged([this](const VLC::MediaPtr &media) {
      send_metadata_change(media);
    });

    event_manager.onPlaying([this]() {
      send_state_change(libvlc_Playing);
    });

    event_manager.onPaused([this]() {
      send_state_change(libvlc_Paused);
    });

    event_manager.onStopped([this]() {
      send_state_change(libvlc_Stopped);
    });

    event_manager.onNothingSpecial([this]() {
      send_state_change(libvlc_NothingSpecial);
    });

    event_manager.onBuffering([this](float) {
      send_state_change(libvlc_Buffering);
    });

    event_manager.onOpening([this]() {
      send_state_change(libvlc_Opening);
    });

    event_manager.onEndReached([this]() {
      send_state_change(libvlc_Ended);
    });

    event_manager.onPositionChanged([this](float newPosition) {
      send_event("PositionChange", {
        { "position", newPosition },
      });
    });

    event_manager.onSeekableChanged([this](bool newSeekable) {
      send_event("SeekableChange", {
        { "seekable", newSeekable },
      });
    });

    event_manager.onMuted([this]() {
      send_event("MuteChange", {
        { "muted", true },
      });
    });

    event_manager.onUnmuted([this]() {
      send_event("MuteChange", {
        { "muted", false },
      });
    });

    event_manager.onAudioVolume([this](float newVolume) {
      send_event("VolumeChange", {
        { "volume", newVolume },
      });
    });

    event_manager.onTimeChanged([this](int64_t newTime) {
      send_event("TimeChange", {
        { "time", newTime },
      });
    });
  }

  inline void print_client_info(websocketpp::connection_hdl hdl, const std::string& prefix) {
    auto connection = m_server.get_con_from_hdl(hdl);
    std::string remoteEndpoint = connection->get_remote_endpoint();
    std::string userAgent = connection->get_request_header("User-Agent");

    spdlog::info("{}: {} {}", prefix, userAgent, remoteEndpoint);
  }

  void on_open(websocketpp::connection_hdl hdl) {
    m_connections.insert(hdl);
    print_client_info(hdl, "Client connected");
  }

  void on_close(websocketpp::connection_hdl hdl) {
    m_connections.erase(hdl);
    print_client_info(hdl, "Client disconnected");
  }

  void on_message(websocketpp::connection_hdl hdl, WebsocketServer::message_ptr msg) {
    // Parse the message as a json object
    std::string payload = msg->get_payload();
    JSON request = JSON::parse(payload);

    spdlog::info("Request: {}", payload);

    // Check if the message is a valid JSON-RPC 2.0 request
    if (request.contains("jsonrpc") && request["jsonrpc"] == "2.0" && request.contains("id") && request.contains("method")) {
      std::string method = request["method"];
      JSON params = request.value("params", JSON::object());
      JSON result = "OK";
      bool error = false;

      if (method == "Open") {
        error = !open_media_list(params, result);
      } else if (method == "Play") {
        m_media_list_player.play();
      } else if (method == "Pause") {
        m_media_list_player.pause();
      } else if (method == "Stop") {
        m_media_list_player.stop();
      } else if (method == "Next") {
        m_media_list_player.next();
      } else if (method == "Previous") {
        m_media_list_player.previous();
      } else if (method == "Rate") {
        result = m_media_player.rate();
      } else if (method == "Position") {
        result = m_media_player.position();
      } else if (method == "Volume") {
        result = m_media_player.volume();
      } else if (method == "Seekable") {
        result = m_media_player.isSeekable();
      } else if (method == "State") {
        auto state = m_media_player.state();
        result = state_to_string(state);
      } else if (method == "Metadata") {
        auto media = m_media_player.media();
        result = media != nullptr ? get_metadata(media) : nullptr;
      } else if (method == "SetMute") {
        error = !set_mute(params, result);
      } else if (method == "SetVolume") {
        error = !set_volume(params, result);
      } else if (method == "SetPosition") {
        error = !set_position(params, result);
      } else if (method == "SetRate") {
        error = !set_rate(params, result);
      } else {
        error = true;
        result = "Unknown method";
      }

      // Send a JSON-RPC 2.0 response
      JSON response;

      response["jsonrpc"] = "2.0";
      response["id"] = request["id"];

      if (error) {
        response["error"] = result;
      } else {
        response["result"] = result;
      }

      m_server.send(hdl, response.dump(), msg->get_opcode());
    }
  }

  bool open_media_list(const JSON& params, JSON& result) {
    if (params.is_array() && params.size() > 0) {
      // Create a media list
      VLC::MediaList mediaList(m_vlc_instance);
      static std::vector<std::tuple<libvlc_meta_t, std::string>> items = {
        { libvlc_meta_Title, "title" },
        { libvlc_meta_Description, "description" },
        { libvlc_meta_Album, "album_title" },
        { libvlc_meta_Artist, "album_artist" },
        { libvlc_meta_ArtworkURL, "artwork_url" },
      };

      // Add each media file to the list
      for (const auto& param : params) {
        if (param.is_object() && param.contains("media_url")) {
          std::string media_url = param["media_url"];
          VLC::Media media(m_vlc_instance, media_url, VLC::Media::FromLocation);

          for (const auto& item : items) {
            libvlc_meta_t type = std::get<0>(item);
            std::string field = std::get<1>(item);

            if (param.contains(field)) {
              media.setMeta(type, param[field]);
            }
          }

          mediaList.addMedia(media);
        } else {
          result = "Missing media_url parameter";

          return false;
        }
      }

      m_media_list_player.stop();

      // Set the media list
      m_media_list_player.setMediaList(mediaList);

      // Play the media list
      m_media_list_player.play();

      // Sending metadata change event
      auto playingMedia = m_media_player.media();
      if (playingMedia != nullptr) {
        send_metadata_change(playingMedia);
      }

      return true;
    }

    result = "Invalid params";

    return false;
  }

  bool set_mute(const JSON& params, JSON& result) {
    if (params.contains("mute")) {
      bool mute = params["mute"];
      m_media_player.setMute(mute);

      return true;
    }

    result = "Missing mute parameter";

    return false;
  }

  bool set_volume(const JSON& params, JSON& result) {
    if (params.contains("volume")) {
      int volume = params["volume"];
      m_media_player.setVolume(volume);

      return true;
    }

    result = "Missing volume parameter";

    return false;
  }

  bool set_position(const JSON& params, JSON& result) {
    if (params.contains("position")) {
      float position = params["position"];
      m_media_player.setPosition(position);

      return true;
    }

    result = "Missing position parameter";

    return false;
  }

  bool set_rate(const JSON& params, JSON& result) {
    if (params.contains("rate")) {
      float rate = params["rate"];
      m_media_player.setRate(rate);

      return true;
    }

    result = "Missing position parameter";

    return false;
  }

  inline std::string state_to_string(libvlc_state_t state) {
    switch (state) {
      case libvlc_Opening:
        return "opening";
      case libvlc_Buffering:
        return "buffering";
      case libvlc_Playing:
        return "playing";
      case libvlc_Paused:
        return "paused";
      case libvlc_NothingSpecial:
      case libvlc_Stopped:
        return "stopped";
      case libvlc_Ended:
        return "ended";
      case libvlc_Error:
        return "error";
      default:
        return "unknown";
    }
  }

  inline void send_state_change(libvlc_state_t state) {
    send_event("StateChange", {
      { "state", state_to_string(libvlc_Playing) },
    });
  }

  inline void send_metadata_change(const VLC::MediaPtr &media) {
    auto metadata = get_metadata(media);
    send_event("MetadataChange", metadata);
  }

  JSON get_metadata(const VLC::MediaPtr &media) {
    std::string media_path = media->mrl();
    std::string media_title = media->meta(libvlc_meta_Title);
    std::string media_artist = media->meta(libvlc_meta_Artist);
    std::string media_album = media->meta(libvlc_meta_Album);
    std::string media_artwork_url = media->meta(libvlc_meta_ArtworkURL);
    libvlc_time_t media_length = media->duration();

    return {
      { "media_url", media_path },
      { "title", media_title },
      { "artist", media_artist },
      { "album", media_album },
      { "artwork_url", media_artwork_url },
      { "length", static_cast<int64_t>(media_length) },
    };
  }

  void send_event(const std::string& event, const JSON& params = JSON()) {
    // Send a JSON-RPC 2.0 notification to all connected clients
    JSON notification;

    notification["jsonrpc"] = "2.0";
    notification["method"] = event;

    if (!params.is_null()) {
      notification["params"] = params;
    }

    std::string message = notification.dump();

    for (auto& hdl : m_connections) {
      m_server.send(hdl, message, websocketpp::frame::opcode::text);
    }
  }

  WebsocketServer m_server;
  std::set<websocketpp::connection_hdl, std::owner_less<websocketpp::connection_hdl>> m_connections;
  VLC::Instance m_vlc_instance;
  VLC::MediaPlayer m_media_player;
  VLC::MediaListPlayer m_media_list_player;
  uint16_t m_port;
};

PlayerServer::PlayerServer(uint16_t port, int vlc_argc, const char **vlc_argv)
  : d(new PlayerServerPrivate(port, vlc_argc, vlc_argv)) {}

PlayerServer::~PlayerServer() {
  delete d;
}

uint16_t PlayerServer::port() const {
  return d->m_port;
}

void PlayerServer::run() {
  d->m_server.set_reuse_addr(true);

  // Listen on the specified port
  d->m_server.listen(d->m_port);

  // Start accepting connections
  d->m_server.start_accept();

  // Start the asio loop
  d->m_server.run();
}

void PlayerServer::stop() {
  spdlog::info("Stopping...");
  d->m_server.stop_listening();

  for (auto& hdl : d->m_connections) {
    d->m_server.close(hdl, 0, "Stopped");
  }
}
