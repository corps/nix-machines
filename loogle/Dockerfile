FROM buildpack-deps:stable

ENV ELAN_HOME=/usr/local/elan \
    PATH=/usr/local/elan/bin:$PATH \
    LEAN_VERSION=leanprover/lean4:nightly

RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | sh -s -- -y --no-modify-path --default-toolchain $LEAN_VERSION; \
    chmod -R a+w $ELAN_HOME; \
    elan --version; \
    lean --version; \
    leanc --version; \
    lake --version;

# Bump to upgrade: 1
RUN git clone https://github.com/nomeata/loogle.git

# Bump to upgrade: 1
RUN apt-get update
RUN apt-get install -y python3 python3-venv
RUN python3 --version

WORKDIR /loogle

COPY server.sh .
RUN sed -i 's/localhost/0.0.0.0/' server.py
RUN python3 -m venv /loogle/venv
RUN /loogle/venv/bin/pip3 install prometheus_client

CMD /loogle/server.sh
