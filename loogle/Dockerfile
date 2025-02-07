FROM buildpack-deps:stable

ENV ELAN_HOME=/usr/local/elan \
    PATH=/usr/local/elan/bin:$PATH \
    LEAN_VERSION=leanprover/lean4:nightly

RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y --no-modify-path --default-toolchain $LEAN_VERSION; \
    chmod -R a+w $ELAN_HOME; \
    elan --version; \
    lean --version; \
    leanc --version; \
    lake --version; \

RUN python --version

CMD jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root
