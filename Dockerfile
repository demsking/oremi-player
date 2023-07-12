FROM oremi-player-build:latest as build

COPY src /app/src
COPY Makefile build.nix /app/

RUN make -C /app build CXXFLAGS="-I/include" LDFLAGS="-L/lib"

# ---

FROM oremi-player-base

ENV ENABLE_SNAPCAST=false

COPY --from=build /app/dist/oremi-player /bin

COPY player/pulse-client.conf /etc/pulse/client.conf
COPY player/entrypoint.sh /oremi/entrypoint.sh

EXPOSE 3765

ENTRYPOINT ["/oremi/entrypoint.sh"]
