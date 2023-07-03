FROM debian:11

ENV DEBIAN_FRONTEND=noninteractive

RUN mkdir -p /etc/apt/keyrings \
  && apt-get update \
  && apt-get install -y curl \
  && curl -o /etc/apt/keyrings/mopidy-archive-keyring.gpg -L https://apt.mopidy.com/mopidy.gpg \
  && curl -o /etc/apt/sources.list.d/mopidy.list -L https://apt.mopidy.com/bullseye.list \
  && apt-get update \
  && apt-get install -y --no-install-recommends \
    mopidy \
    python3-pip \
    gstreamer1.0-plugins-good \
    gstreamer1.0-plugins-ugly \
    gstreamer1.0-tools \
    gstreamer1.0-alsa \
  && apt-get remove -y curl \
  && apt-get clean \
  && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install \
  Mopidy-InternetArchive \
  Mopidy-Podcast-iTunes \
  Mopidy-Podcast \
  Mopidy-SoundCloud \
  Mopidy-TuneIn \
  Mopidy-Iris \
  Mopidy-MPD

RUN useradd -ms /bin/bash oremi \
  && gpasswd -a oremi audio \
  && chown -R oremi /var/lib/mopidy

ADD pulse-client.conf /etc/pulse/client.conf
ADD mopidy.conf /oremi/mopidy.conf

USER oremi
WORKDIR /home/oremi

EXPOSE 6600
EXPOSE 6680
EXPOSE 6681

ENTRYPOINT ["mopidy", "--config", "/oremi/mopidy.conf:/etc/mopidy.conf"]
