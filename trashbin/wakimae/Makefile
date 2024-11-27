deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=wakimae=true')" ]; then docker node update $$(hostname) --label-add wakimae=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk

update::
	docker compose run app bash -c 'cd src && alembic upgrade heads'

.PHONY: up
up: # Runs development server
	docker compose up

.PHONY: down
down:
	docker compose down
	docker image prune
	docker container prune

.PHONY: migration
migration:
	docker compose run app bash -c 'cd src && alembic revision --autogenerate -m Migration'
