IMAGE_VERSION := 1.3.0
IMAGE_PLAYER_NAME := demsking/oremi-player
IMAGE_SNAPSERVER_NAME := demsking/oremi-snapserver

MOPIDY_CONF_FILES := $(wildcard mopidy*.conf) pulse-client.conf
SNAPSERVER_CONF_FILES := $(wildcard snap*.conf)
SH_FILES := $(wildcard *.sh)

.PHONY: build-player build-snapserver build-images publish-images

build-player: player.Dockerfile $(MOPIDY_CONF_FILES) $(SH_FILES)
	docker build . -f player.Dockerfile -t $(IMAGE_PLAYER_NAME):$(IMAGE_VERSION) \
		&& docker build . -f player.Dockerfile -t $(IMAGE_PLAYER_NAME):latest

build-snapserver: snapserver.Dockerfile $(SNAPSERVER_CONF_FILES)
	docker build . -f snapserver.Dockerfile -t $(IMAGE_SNAPSERVER_NAME):$(IMAGE_VERSION) \
		&& docker build . -f snapserver.Dockerfile -t $(IMAGE_SNAPSERVER_NAME):latest

build-images: build-player build-snapserver

publish-images: build-images
	git commit . -m "Release $(IMAGE_VERSION)"
	git tag v$(IMAGE_VERSION)
	docker push $(IMAGE_PLAYER_NAME):$(IMAGE_VERSION)
	docker push $(IMAGE_PLAYER_NAME):latest
	docker push $(IMAGE_SNAPSERVER_NAME):$(IMAGE_VERSION)
	docker push $(IMAGE_SNAPSERVER_NAME):latest
