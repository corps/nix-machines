deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=ankillio=true')" ]; then docker node update $$(hostname) --label-add ankillio=true; fi

include ../maketools/help.mk
include ../maketools/docker.mk

setup:
	if [ -n venv ]; then python -m venv venv; fi
	venv/bin/pip install -r requirements.frozen.txt

update-packages:
	pip-compile --upgrade --strip-extras --quiet requirements.txt -o requirements.frozen.txt
