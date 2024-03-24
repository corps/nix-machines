deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=libbiz=true')" ]; then docker node update $$(hostname) --label-add libbiz=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk

up: # Runs development server
	docker-compose up -d

down:
	docker-compose down
	docker image prune
	docker container prune
