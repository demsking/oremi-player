# Oremi Player Server

[![Buy me a beer](https://img.shields.io/badge/Buy%20me-a%20beer-1f425f.svg)](https://www.buymeacoffee.com/demsking)

Oremi Player Server is a [Mopidy](https://mopidy.com/) server preconfigured for 
the Oremi Personal Assistant.

## Start

Start Oremi Player Server:

```sh
docker run -d \
  --name oremi-player \
  -p 5216:5216 \
  -p 6600:6600 \
  -v ~/.local/mobidy/data:/var/lib/mopidy/data \
  -v ~/.cache/mobidy:/var/lib/mopidy/cache \
  -v ~/Music/:/media \
  -v /run/user/1000/pulse:/run/user/1000/pulse \
  demsking/oremi-player:1.0.0
```

Open http://localhost:5216

## License

Under the MIT license.
See [LICENSE](https://gitlab.com/demsking/oremi-player/blob/main/LICENSE)
file for more details.
