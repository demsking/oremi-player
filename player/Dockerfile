FROM alpine:3.18.2 as build
RUN apk add --no-cache --upgrade python3 \
  && python3 -m ensurepip
RUN python3 -m pip install --no-cache-dir poetry
COPY app /app
RUN cd /app && poetry build

# ---

FROM alpine:3.18.2

ENV ENABLE_SNAPCAST=false
ENV PYTHONPATH=/opt/oremi/packages

COPY --from=build /app/dist $PYTHONPATH

RUN apk add --no-cache --upgrade \
    vlc \
    python3 \
    pulseaudio-alsa

RUN addgroup -S oremi \
  && adduser -S oremi -u 1000 -G oremi

USER oremi
WORKDIR /home/oremi

ENV PATH=/home/oremi/.local/bin:$PATH

RUN python3 -m ensurepip \
  && python3 -m pip install --no-cache-dir $PYTHONPATH/*.whl

COPY pulse-client.conf /etc/pulse/client.conf
COPY entrypoint.sh /oremi/entrypoint.sh

EXPOSE 3765

ENTRYPOINT ["/oremi/entrypoint.sh"]