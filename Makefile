.PHONY: build-image publish-image

build-image:
	docker build . -t demsking/oremi-player:1.0.0 \
		&& docker build . -t demsking/oremi-player:latest

publish-image:
	docker push demsking/oremi-player:1.0.0 \
		&& docker push demsking/oremi-player:latest
