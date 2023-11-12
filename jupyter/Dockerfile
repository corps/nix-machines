FROM jupyter/tensorflow-notebook
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#core-stacks
ENV PYTHONPATH=/home/jovyan
COPY install_chatbot.py .
RUN python3 ./install_chatbot.py

