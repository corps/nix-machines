deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=portainer=true')" ]; then docker node update $$(hostname) --label-add portainer=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk
