FROM jupyter/tensorflow-notebook
# https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#core-stacks
RUN mamba install --quiet --yes \
    dropbox google-api-python-client google-auth-httplib2 google-auth-oauthlib \
    ipywidgets \
    && \
    mamba clean --all -f -y && \
    fix-permissions "${CONDA_DIR}" && \
    fix-permissions "/home/${NB_USER}"

CMD ["start-notebook.sh", "--NotebookApp.password='argon2:$argon2id$v=19$m=10240,t=10,p=8$2NWJkwYTtxatvj+4Tyz61Q$0U1dMk+Wvoq5tFt9Z/JianidtEzsbAKbvxZjehOgtgo'"]
