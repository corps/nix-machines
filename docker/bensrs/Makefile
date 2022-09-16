tmp:=$(shell mktemp)

.PHONY: all
all: deploy

.PHONY: deploy
deploy:
	docker stack deploy bensrs --compose-file bensrs.yml
	docker service update bensrs_app
