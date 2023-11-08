project_name:=$(shell basename $(abspath .))

ifeq ($(wildcard Dockerfile),Dockerfile)
.PHONY: image
image:: # builds the Dockerfile of this project, including all dependent images
	../maketools/build-image.py Dockerfile

.PHONY: push
push:: image # Builds and pushes the latest Dockerfile for the project
	docker tag $(project_name) corps/$(project_name):latest
	docker push corps/$(project_name):latest
endif

ifeq ($(wildcard stack.yml),stack.yml)
.PHONY: deploy
deploy:: # builds the docker stack from the stack.yml file
	../maketools/deploy-stack.py stack.yml

configure: # Configure and then deploy any files in the stack
	../maketools/configure-stack.py stack.yml
endif

