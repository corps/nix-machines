tmp:=$(shell mktemp)

.PHONY: all
all: push deploy

.PHONY: deploy
deploy:
	docker stack deploy ngrok --compose-file ngrok.yml
	docker service update ngrok_agent

.PHONY: push
push: build-image
	docker push corps/ngrok:latest

.PHONY: build-image
build-image:
	cat $$(nix-build base-image.nix) | docker load
	docker build . --tag corps/ngrok:latest

config:
	echo $(tmp)
	docker config inspect ngrok.yml | grep "Data" | cut -d '"' -f 4 | base64 --decode > $(tmp)
	$$EDITOR $(tmp)
	docker config create ngrok.yml.new ${tmp}
	NGROK_YML=ngrok.yml.new $(MAKE) deploy
	docker config rm ngrok.yml
	docker config create ngrok.yml ${tmp}
	$(MAKE) deploy
