FROM jupyter/tensorflow-notebook
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#core-stacks
RUN mamba install --quiet --yes \
    pydantic openapi dropbox google-api-python-client google-auth-httplib2 google-auth-oauthlib \
    ipywidgets \
    && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

COPY ipython_config.py /app/profile_default/
