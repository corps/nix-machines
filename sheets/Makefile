deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=sheets=true')" ]; then docker node update $$(hostname) --label-add sheets=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk

.PHONY: up
up: # Runs development server
	docker-compose up

.PHONY: down
down:
	docker-compose down
	docker image prune
	docker container prune
