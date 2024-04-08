#!/bin/sh

set +e

/usr/bin/snapclient -l
/usr/bin/snapclient \
  --host $SNAPCAST_HOST \
  --port $SNAPCAST_PORT \
  --instance $SNAPCAST_INSTANCE_ID \
  --soundcard "$SNAPCAST_DEVICE" \
  --latency $SNAPCAST_LATENCY
