FROM jupyter/tensorflow-notebook
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#core-stacks

USER root
USER jovyan

ENV PYTHONPATH=/home/jovyan
COPY requirements.txt .
RUN pip3 install -r requirements.txt
