APP_NAME = Oremi Player
APP_VERSION = 1.2.0

IMAGE_VERSION := 1.1.0
IMAGE_PLAYER_NAME := demsking/oremi-player
IMAGE_SNAPCLIENT_NAME := demsking/oremi-snapclient
IMAGE_SNAPSERVER_NAME := demsking/oremi-snapserver

PLAYER_FILES := $(wildcard src/* player/*)
SNAPCLIENT_FILES := $(wildcard snapclient/*)
SNAPSERVER_FILES := $(wildcard snapserver/*)

LIBVLCPP_VERSION = master
LIBVLCPP_FILENAME = libvlcpp-$(LIBVLCPP_VERSION)
LIBVLCPP_URL = https://code.videolan.org/videolan/libvlcpp/-/archive/$(LIBVLCPP_VERSION)/$(LIBVLCPP_FILENAME).tar.gz

SPDLOG_VERSION = 1.12.0
SPDLOG_FILENAME = spdlog-$(SPDLOG_VERSION)
SPDLOG_URL = https://github.com/gabime/spdlog/archive/refs/tags/v$(SPDLOG_VERSION).tar.gz

SOURCES := $(wildcard src/*.cpp)
OBJECTS := $(patsubst %.cpp,build/%.o,$(SOURCES))

.PHONY: all clean build build-player build-snapclient build-snapserver build-images publish-images prepare

include/vlcpp:
	wget --no-check-certificate $(LIBVLCPP_URL) -O $(LIBVLCPP_FILENAME).tar.gz
	tar xzf $(LIBVLCPP_FILENAME).tar.gz
	mkdir -p $@
	mv $(LIBVLCPP_FILENAME)/vlcpp include
	rm -rf $(LIBVLCPP_FILENAME) $(LIBVLCPP_FILENAME).tar.gz

include/spdlog:
	wget --no-check-certificate $(SPDLOG_URL) -O $(SPDLOG_FILENAME).tar.gz
	tar xzf $(SPDLOG_FILENAME).tar.gz
	mkdir -p $@
	mv $(SPDLOG_FILENAME)/$@ include
	rm -rf $(SPDLOG_FILENAME) $(SPDLOG_FILENAME).tar.gz

clean:
	rm -rf dist/ build/ include/

prepare: include/vlcpp include/spdlog
	mkdir -p dist
	mkdir -p build/src

build/%.o: %.cpp build.nix | prepare
	g++ -v -std=c++17 -pthread -DAPP_NAME="\"$(APP_NAME)\"" -DAPP_VERSION="\"$(APP_VERSION)\"" -c -o $@ $< -Iinclude $(CXXFLAGS)

dist/oremi-player: $(OBJECTS) build.nix
	g++ -v -std=c++17 -pthread -DAPP_NAME="\"$(APP_NAME)\"" -DAPP_VERSION="\"$(APP_VERSION)\"" -o $@ $(OBJECTS) -lvlc $(LDFLAGS)

build: dist/oremi-player

build/images/oremi-player-build.tar.gz: build.nix
	nix-build --out-link $@ $<
	docker load < $@

build/images/oremi-player-base.tar.gz: image.nix
	nix-build --out-link $@ $<
	docker load < $@

build-player: $(PLAYER_FILES) build/images/oremi-player-build.tar.gz build/images/oremi-player-base.tar.gz
	docker build . -t $(IMAGE_PLAYER_NAME):$(APP_VERSION) \
		&& docker build . -t $(IMAGE_PLAYER_NAME):latest

build-snapclient: $(SNAPCLIENT_FILES)
	docker build snapclient -t $(IMAGE_SNAPCLIENT_NAME):$(IMAGE_VERSION) \
		&& docker build snapclient -t $(IMAGE_SNAPCLIENT_NAME):latest

build-snapserver: $(SNAPSERVER_FILES)
	docker build snapserver -t $(IMAGE_SNAPSERVER_NAME):$(IMAGE_VERSION) \
		&& docker build snapserver -t $(IMAGE_SNAPSERVER_NAME):latest

images: build-player build-snapclient build-snapserver

publish: build-images
	git commit . -m "Release $(APP_NAME) $(APP_VERSION) with Snapcast images $(IMAGE_VERSION)"
	git tag v$(APP_VERSION)
	docker push $(IMAGE_PLAYER_NAME):$(APP_VERSION)
	docker push $(IMAGE_PLAYER_NAME):latest
	docker push $(IMAGE_SNAPCLIENT_NAME):$(IMAGE_VERSION)
	docker push $(IMAGE_SNAPCLIENT_NAME):latest
	docker push $(IMAGE_SNAPSERVER_NAME):$(IMAGE_VERSION)
	docker push $(IMAGE_SNAPSERVER_NAME):latest
	git push --tags origin main
