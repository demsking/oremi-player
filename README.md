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
  -p 3765:3765 \
  -v /run/user/1000/pulse:/run/user/1000/pulse \
  -v /etc/localtime:/etc/localtime:ro \
  demsking/oremi-player
```

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
        - /run/user/1000/pulse:/run/user/1000/pulse
        - /etc/localtime:/etc/localtime:ro
        - /tmp/snapfifo:/tmp/snapfifo
      ports:
        - 6680:6680
    snapserver:
      image: demsking/oremi-snapserver
      volumes:
        - ~/.local/snapserver:/var/lib/snapserver
        - /etc/localtime:/etc/localtime:ro
        - /tmp/snapfifo:/tmp/snapfifo
      ports:
        - 1705:1705
        - 1704:1704
        - 1780:1780
    snapclient:
      image: demsking/oremi-snapclient
      privileged: true
      environment:
        SNAPCAST_HOST: snapserver
        SNAPCAST_PORT: 1704
        SNAPCAST_DEVICE: sysdefault
      volumes:
        - /dev/snd:/dev/snd
        - /etc/localtime:/etc/localtime:ro
  ```

3. Run Docker Compose

  ```sh
  docker-compose up -d
  ```

**URLs**

- Snapweb: http://localhost:1780

## Oremi Player WebSocket JSON-RPC API

This section describes the JSON-RPC API of the Oremi Player WebSocket
JSON-RPC API.

## Overview

The Oremi Player server provides a JSON-RPC 2.0 API for controlling a
Oremi Player instance through a websocket connection.
Clients can send JSON-RPC 2.0 requests to the server to perform actions
such as opening a media file, playing, pausing, stopping, setting the
volume, and setting the position. The server sends JSON-RPC 2.0
notifications to clients when events such as playing, paused, stopped,
end reached, and encountered error occur.

## Methods

The following methods are available on the server:

- `Play`
  Starts playback of the media player.

  **Return Value**
  - (string): `"OK"` if the method was called successfully.

- `Pause`
  Pauses playback of the media player.

  **Return Value**
  - (string): `"OK"` if the method was called successfully.

- `Stop`
  Stops playback of the media player.

  **Return Value**
  - (string): `"OK"` if the method was called successfully.

- `Next`
  Skips to the next item in the media list.

  **Return Value**
  - (string): `"OK"` if the method was called successfully.

- `Previous`
  Skips to the previous item in the media list.

  **Return Value**
  - (string): `"OK"` if the method was called successfully.

- `Rate`
  Gets the playback rate of the media player.

  **Return Value**
  - (float): The current playback rate of the media player.

- `Position`
  Gets the position of the media player.

  **Return Value**
  - (float): The current position of the media player.

- `Volume`
  Gets the volume of the media player.

  **Return Value**
  - (float): The current volume of the media player.

- `Seekable`
  Gets whether or not the media player is seekable.

  **Return Value**
  - (bool): Whether or not the media player is seekable.

- `State`
  Gets the state of the media player.

  **Return Value**
  - (string): The current state of the media player. Possible values are: `playing`, `paused`, `stopped`

- `Metadata`
  Gets the metadata of the current media.

  **Return Value**
  - (object or null): An object containing metadata for the current media if metadata is available, otherwise `null`. The object has the following properties:
    - `title` (string): The title of the media.
    - `description` (string): The description of the media.
    - `media_url` (string): The URL to the media. This parameter is mandatory.
    - `artwork_url` (string): The URL to the artwork.
    - `album_title` (string): The title of the album.
    - `album_artist` (string): The album artist.
    - `artist_name` (string): The name of the artist.

- `Open`
  Opens a media list.

  **Parameters**
  - `title` (string): The title of the media.
  - `description` (string): The description of the media.
  - `media_url` (string): The URL to the media. This parameter is mandatory.
  - `artwork_url` (string): The URL to the artwork.
  - `album_title` (string): The title of the album.
  - `album_artist` (string): The album artist.
  - `artist_name` (string): The name of the artist.

  **Return Value**
  - (string): `"OK"` if the method was called successfully.

- `SetMute`
  Sets whether or not the media player is muted.

  **Parameters**
  - `muted` (bool): Whether or not to mute the media player.

   **Return Value**
   - (string): `"OK"` if the method was called successfully.

- `SetVolume`
   Sets the volume of the media player.

   **Parameters**
   - `volume` (float): The new volume of the media player.

   **Return Value**
   - (string): `"OK"` if the method was called successfully.

- `SetPosition`
  Sets the position of the media player.

  **Parameters**
  - `position` (float): The new position of the media player.

  **Return Value**
  - (string): `"OK"` if the method was called successfully.

- `SetRate`
  Sets the playback rate of the media player.

  **Parameters**
  - `rate` (float): The new playback rate of the media player.

  **Return Value**
  - (string): `"OK"` if the method was called successfully.

## Notifications

The following notifications are sent by the server:

- `StateChange`
  Indicates that the state of the media player has changed.

  **Parameters**
  - `state` (string): The new state of the media player.
    Possible values are:
      - `playing`
      - `paused`
      - `stopped`

- `PositionChange`
  Indicates that the position of the media player has changed.

  **Parameters**
  - `position` (float): The new position of the media player.

- `SeekableChange`
  Indicates that the seekable status of the media player has changed.

  **Parameters**
  - `seekable` (bool): The new seekable status of the media player.

- `MuteChange`
  Indicates that the mute status of the media player has changed.

  **Parameters**
  - `muted` (bool): The new mute status of the media player.

- `VolumeChange`
  Indicates that the volume of the media player has changed.

  **Parameters**
  - `volume` (float): The new volume of the media player.

- `TimeChange`
  Indicates that the time of the media player has changed.

  **Parameters**
  - `time` (int64_t): The new time of the media player.

- `MetadataChange`
  Indicates that the metadata of the media player has changed.

  **Parameters**
  - `album` (string): The album name.
  - `artist` (string): The artist name.
  - `artwork_url` (string): The URL to the artwork.
  - `length` (int): The length of the media in seconds.
  - `media_url` (string): The URL to the media.
  - `title` (string): The title of the media.

## License

Under the MIT license.
See [LICENSE](https://gitlab.com/demsking/oremi-player/blob/main/LICENSE)
file for more details.
