root:=$(shell dirname $(shell dirname $(lastword $(MAKEFILE_LIST))))
tag_name:=$(shell realpath --relative-to="$(root)" . | tr '/' ':')
project_name:=$(shell realpath --relative-to="$(root)" .)
compose_app:=app
source_volumes:=
shell:=bash
ports:=

.PHONY: update
update:: # Updates development services

ifeq ($(wildcard docker-compose.yml),docker-compose.yml)
run:=docker-compose run $(compose_app)
.PHONY: run
run: # Runs the service
	docker-compose up

.PHONY: update
update:: # Updates development services
	docker-compose build
else
run:=docker run -it --rm $(source_volumes) $(ports) $(tag_name)
.PHONY: run
run: image # Runs the service
	$(run)
endif


.PHONY: shell
shell: # Opens a shell in the docker environment
	$(run) $(shell)

ifeq ($(wildcard Dockerfile),Dockerfile)
.PHONY: image
image:: # builds the Dockerfile of this project, including all dependent images
	$(root)/maketools/build-image.py Dockerfile

.PHONY: push
push:: image # Builds and pushes the latest Dockerfile for the project
	docker tag $(tag_name) corps/$(project_name):latest
	docker push corps/$(project_name):latest
endif

ifeq ($(wildcard stack.yml),stack.yml)
.PHONY: deploy
deploy:: # builds the docker stack from the stack.yml file
	$(root)/maketools/deploy-stack.py stack.yml

.PHONY: configure
configure:: # Configure and then deploy any files in the stack
	$(root)/maketools/configure-stack.py stack.yml

.PHONY: compost
compost:: image push deploy # Bootstraps the stack
	@echo Ready!
endif
