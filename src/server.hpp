#ifndef PLAYER_SERVER_HPP
#define PLAYER_SERVER_HPP

#ifndef APP_NAME
  #define APP_NAME "\"Oremi Player\""
#endif

#ifndef APP_VERSION
  #define APP_VERSION "\"1.0.0\""
#endif

#define STRINGIFY(x) #x
#define TOSTRING(x) STRINGIFY(x)
#define APP_USER_AGENT APP_NAME " " APP_VERSION

class PlayerServerPrivate;

class PlayerServer {
public:
  PlayerServer(uint16_t port, int vlc_argc, const char **vlc_argv);
  ~PlayerServer();

  uint16_t port() const;
  void run();
  void stop();

private:
  PlayerServerPrivate* const d;
};

#endif  // PLAYER_SERVER_HPP
