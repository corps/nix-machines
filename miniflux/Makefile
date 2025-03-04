deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=miniflux-db=true')" ]; then docker node update $$(hostname) --label-add miniflux-db=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk
