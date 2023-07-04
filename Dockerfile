FROM alpine:3.18.2

RUN apk add --no-cache --upgrade \
    snapcast \
    mopidy \
    python3 \
    gstreamer \
    supervisor \
  && python3 -m ensurepip

RUN addgroup -S oremi \
  && adduser -S oremi -u 1000 -G oremi \
  && chown -R oremi /var/lib/mopidy

USER oremi
WORKDIR /home/oremi

RUN python3 -m pip install \
  Mopidy-InternetArchive \
  Mopidy-Podcast-iTunes \
  Mopidy-Podcast \
  Mopidy-SoundCloud \
  Mopidy-TuneIn \
  Mopidy-Iris

COPY pulse-client.conf /etc/pulse/client.conf
COPY mopidy.conf /oremi/mopidy.conf
COPY snapserver.conf /oremi/snapserver.conf
COPY supervisord.conf /etc/supervisord.conf

# Mopidy port
EXPOSE 36680

# SnapCast HTTP port
EXPOSE 31780

# SnapCast TCP port
EXPOSE 31705

# SnapCast Stream port
EXPOSE 31704

ENTRYPOINT ["/usr/bin/supervisord", "-c", "/etc/supervisord.conf"]
