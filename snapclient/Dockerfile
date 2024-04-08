FROM alpine:3.18.2

ENV SNAPCAST_PORT=1704
ENV SNAPCAST_DEVICE=default
ENV SNAPCAST_INSTANCE_ID=
ENV SNAPCAST_LATENCY=0

RUN apk add --no-cache --upgrade snapcast alsa-utils

RUN addgroup -S oremi \
  && adduser -S oremi -u 1000 -G oremi audio

USER oremi
WORKDIR /home/oremi

COPY entrypoint.sh /oremi/entrypoint.sh

ENTRYPOINT ["/oremi/entrypoint.sh"]
