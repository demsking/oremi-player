#!/bin/sh

set +ex

if [ "$ENABLE_SNAPCAST" = "true" ]; then
  mopidy --config /oremi/mopidy_snapcast.conf:/oremi/mopidy.conf
else
  mopidy --config /oremi/mopidy.conf
fi
