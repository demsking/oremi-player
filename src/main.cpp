#include <csignal>
#include <iostream>
#include "spdlog/spdlog.h"
#include "server.hpp"

PlayerServer* server = nullptr;

void handle_signal(int signal) {
  if (server != nullptr) {
    server->stop();
  }
}

int main(int argc, char *argv[]) {
  spdlog::set_pattern("%Y-%m-%d %H:%M:%S %e - %^%l%$ - %v");
  spdlog::info("Starting {} {}", APP_NAME, APP_VERSION);

  // Parse command line arguments
  bool snapcast = false;
  bool debug = false;
  uint16_t port = 3765;
  std::string certs_dir = "/etc/ssl/certs";

  for (int i = 1; i < argc; i++) {
    std::string arg = argv[i];

    if (arg == "--snapcast") {
      snapcast = true;
    } else if (arg == "--port" && i + 1 < argc) {
      port = std::stoi(argv[++i]);
    } else if (arg == "--certs-dir" && i + 1 < argc) {
      certs_dir = argv[++i];
    } else if (arg == "--debug") {
      debug = true;
    } else {
      std::cerr << "Unknown argument: " << arg << std::endl;

      return 1;
    }
  }

  // Set logging level based on debug mode
  if (debug) {
    spdlog::set_level(spdlog::level::debug);
    spdlog::debug("Debug mode enabled");
  } else {
    spdlog::set_level(spdlog::level::info);
  }

  // VLC command-line arguments
  const char *vlc_argv[] = {
    "--no-dbus",
    "--no-video",
    "--no-sout-video",
    "--no-osd",
    "--no-stats",
    "--no-loop",
    "--no-repeat",
    "--no-plugins-scan",
    "--no-play-and-exit",
    "--no-sub-autodetect-file",
    "--no-metadata-network-access",
    "--no-xlib",
    "--gnutls-dir-trust", certs_dir.c_str(),
    "--quiet",
    "--verbose", "0",
  };

  int vlc_argc = sizeof(vlc_argv) / sizeof(*vlc_argv);

  try {
    // Add conditional options
    if (snapcast) {
      const char *snapcast_argv[] = {
        "--aout", "afile",
        "--audiofile-file", "/tmp/snapfifo",
      };

      int snapcast_argc = sizeof(snapcast_argv) / sizeof(*snapcast_argv);
      const char **combined_argv = new const char *[vlc_argc + snapcast_argc];
      std::copy(vlc_argv, vlc_argv + vlc_argc, combined_argv);
      std::copy(snapcast_argv, snapcast_argv + snapcast_argc, combined_argv + vlc_argc);

      server = new PlayerServer(port, vlc_argc + snapcast_argc, combined_argv);
      delete[] combined_argv;
    } else {
      server = new PlayerServer(port, vlc_argc, vlc_argv);
    }

    // Set the signal handler
    std::signal(SIGINT, handle_signal);
    std::signal(SIGSTOP, handle_signal);

    // Run the server
    spdlog::info("Listening {}", server->port());
    server->run();
    delete server;

    spdlog::info("Server stopped");
  } catch (const std::runtime_error &e) {
    spdlog::error("Runtime error: {}", e.what());
  }

  return 0;
}
