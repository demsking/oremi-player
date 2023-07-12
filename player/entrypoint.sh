#!/bin/sh

set +e

if [ $ENABLE_SNAPCAST = true ]; then
  oremi-player --port 3765 --certs-dir /etc/ssl/certs --snapcast
else
  oremi-player --port 3765 --certs-dir /etc/ssl/certs
fi
