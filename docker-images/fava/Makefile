DOCKER:=docker --config ../docker-config

push: load setup
	$(DOCKER) tag fava:latest corps/fava:latest
	$(DOCKER) push corps/fava:latest

.PHONY: setup
setup:
	make -C ../ setup

load: result
	$(DOCKER) load -i result

result: default.nix
	nix-build

