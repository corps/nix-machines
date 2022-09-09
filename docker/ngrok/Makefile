.PHONY: deploy
deploy: push
	docker stack deploy ngrok --compose-file ngrok.yml

.PHONY: push
push: build-image
	docker push corps/ngrok:latest

.PHONY: build-image
build-image:
	cat $$(nix-build base-image.nix) | docker load
	docker build . --tag corps/ngrok:latest
