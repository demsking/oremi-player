FROM alpine:3.18.2

RUN apk add --no-cache --upgrade snapcast

RUN addgroup -S oremi \
  && adduser -S oremi -u 1000 -G oremi

USER oremi
WORKDIR /home/oremi

COPY snapserver.conf /oremi/snapserver.conf

# Snapcast HTTP port
EXPOSE 1780

# Snapcast TCP port
EXPOSE 1705

# Snapcast Stream port
EXPOSE 1704

ENTRYPOINT ["/usr/bin/snapserver", "-c", "/oremi/snapserver.conf"]
