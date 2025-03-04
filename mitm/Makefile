deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=mitm=true')" ]; then docker node update $$(hostname) --label-add mitm=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk
