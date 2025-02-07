deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=loogle=true')" ]; then docker node update $$(hostname) --label-add loogle=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk
