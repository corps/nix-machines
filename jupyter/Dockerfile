FROM jupyter/tensorflow-notebook
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#core-stacks

USER root
USER jovyan

COPY requirements.txt .
RUN pip install -r requirements.txt

ENV PYTHONPATH=/home/jovyan
