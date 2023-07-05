FROM alpine:3.18.2

ENV ENABLE_SNAPCAST=false

RUN apk add --no-cache --upgrade \
    mopidy \
    python3 \
    gstreamer \
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
COPY mopidy_snapcast.conf /oremi/mopidy_snapcast.conf
COPY entrypoint.sh /oremi/entrypoint.sh

# Mopidy port
EXPOSE 36680

ENTRYPOINT ["/oremi/entrypoint.sh"]
