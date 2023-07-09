#!/bin/sh

set +e

VLC_DISABLED_OPTS="--no-dbus --no-video --no-plugins-scan --no-play-and-exit --no-xlib"
VLC_ENABLED_OPTS="--daemon"
VLC_LUA_OPTS="--cli-host=0.0.0.0:4212"
VLC_OPTS="$VLC_DISABLED_OPTS $VLC_ENABLED_OPTS $VLC_LUA_OPTS"

if [ $ENABLE_SNAPCAST = true ]; then
  VLC_OPTS="$VLC_OPTS --aout afile --audiofile-file /tmp/snapfifo"
fi

vlc $VLC_OPTS
python3 -m oremi-player --port 3765
