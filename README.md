# Oremi Player Server

[![Buy me a beer](https://img.shields.io/badge/Buy%20me-a%20beer-1f425f.svg)](https://www.buymeacoffee.com/demsking)

Oremi Player Server is a [Mopidy](https://mopidy.com/) and 
[Snapcast](https://github.com/badaix/snapcast) servers
preconfigured for the [Oremi Personal Assistant](https://gitlab.com/demsking/oremi).

## Start

## Start Oremi Player Server

```sh
docker run -d \
  --name oremi-player \
  -p 36680:36680 \
  -v ~/Music/:/media \
  -v ~/.local/mopidy/data:/var/lib/mopidy/data \
  -v ~/.cache/mopidy/cache:/var/lib/mopidy/cache \
  -v /run/user/1000/pulse:/run/user/1000/pulse \
  -v /etc/localtime:/etc/localtime:ro \
  demsking/oremi-player
```

**URLs**

- Mopidy: http://localhost:36680

## Start Oremi Player Server with Snapcast

1. First, create the FIFO file `/tmp/snapfile`:

  ```sh
  mkfifo /tmp/snapfifo
  ```

2. Create Docker Compose File

  ```yaml
  version: '3.8'
  services:
    player:
      image: demsking/oremi-player
      environment:
        ENABLE_SNAPCAST: 'true'
      volumes:
        - ~/Music/:/media
        - ~/.local/player/data:/var/lib/mopidy/data
        - ~/.cache/player/cache:/var/lib/mopidy/cache
        - /run/user/1000/pulse:/run/user/1000/pulse
        - /etc/localtime:/etc/localtime:ro
        - /tmp/snapfifo:/tmp/snapfifo
      ports:
        - 36680:36680
    snapserver:
      image: demsking/oremi-snapserver
      volumes:
        - ~/.local/snapserver:/var/lib/snapserver
        - /etc/localtime:/etc/localtime:ro
        - /tmp/snapfifo:/tmp/snapfifo
      ports:
        - 31705:31705
        - 31704:31704
        - 31780:31780
  ```

3. Run Docker Compose

  ```sh
  docker-compose up -d
  ```

**URLs**

- Mopidy: http://localhost:36680
- Snapweb: http://localhost:31780

## License

Under the MIT license.
See [LICENSE](https://gitlab.com/demsking/oremi-player/blob/main/LICENSE)
file for more details.
