FROM jupyter/tensorflow-notebook
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#core-stacks

USER root
RUN \
    apt-get update && \
    apt-get install -y libvulkan1 libgl1 libglib2.0-0 wget

USER jovyan

RUN \
    wget https://github.com/Juice-Labs/Juice-Labs/releases/latest/download/JuiceClient-linux.tar.gz && \
    tar -xf JuiceClient-linux.tar.gz -C /home/jovyan

ENV PYTHONPATH=/home/jovyan
COPY requirements.txt .
COPY juice.cfg .
RUN pip3 install -r requirements.txt

CMD ./juicify start-notebook.py
