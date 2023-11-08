deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=jupyter=true')" ]; then docker node update $$(hostname) --label-add jupyter=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk
