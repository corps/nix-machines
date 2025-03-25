deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=ankillio=true')" ]; then docker node update $$(hostname) --label-add ankillio=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk

update-packages:
	pip-compile --upgrade --strip-extras --quiet requirements.txt -o requirements.frozen.txt
