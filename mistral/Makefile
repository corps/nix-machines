deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=mistral=true')" ]; then docker node update $$(hostname) --label-add mistral=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk
