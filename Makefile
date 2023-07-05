IMAGE_VERSION := 1.4.0
IMAGE_PLAYER_NAME := demsking/oremi-player
IMAGE_SNAPCLIENT_NAME := demsking/oremi-snapclient
IMAGE_SNAPSERVER_NAME := demsking/oremi-snapserver

PLAYER_FILES := $(wildcard player/*)
SNAPCLIENT_FILES := $(wildcard snapclient/*)
SNAPSERVER_FILES := $(wildcard snapserver/*)

.PHONY: build-player build-snapclient build-snapserver build-images publish-images

build-player: $(PLAYER_FILES)
	docker build player -t $(IMAGE_PLAYER_NAME):$(IMAGE_VERSION) \
		&& docker build player -t $(IMAGE_PLAYER_NAME):latest

build-snapclient: $(SNAPCLIENT_FILES)
	docker build player -t $(IMAGE_SNAPCLIENT_NAME):$(IMAGE_VERSION) \
		&& docker build player -t $(IMAGE_SNAPCLIENT_NAME):latest

build-snapserver: $(SNAPSERVER_FILES)
	docker build player -t $(IMAGE_SNAPSERVER_NAME):$(IMAGE_VERSION) \
		&& docker build player -t $(IMAGE_SNAPSERVER_NAME):latest

build-images: build-player build-snapclient build-snapserver

publish-images: build-images
	git commit . -m "Release $(IMAGE_VERSION)"
	git tag v$(IMAGE_VERSION)
	docker push $(IMAGE_PLAYER_NAME):$(IMAGE_VERSION)
	docker push $(IMAGE_PLAYER_NAME):latest
	docker push $(IMAGE_SNAPCLIENT_NAME):$(IMAGE_VERSION)
	docker push $(IMAGE_SNAPCLIENT_NAME):latest
	docker push $(IMAGE_SNAPSERVER_NAME):$(IMAGE_VERSION)
	docker push $(IMAGE_SNAPSERVER_NAME):latest
