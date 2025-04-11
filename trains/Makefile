deploy::
	if [ -z "$$(docker node ls -q -f 'node.label=trains=true')" ]; then docker node update $$(hostname) --label-add ankillio=trains; fi

include ../maketools/help.mk
include ../maketools/docker.mk

update-packages:
	pip-compile --upgrade --strip-extras --quiet requirements.txt -o requirements.frozen.txt

setup:
	if [ -n venv ]; then python -m venv venv; fi
	venv/bin/pip install -r requirements.frozen.txt
