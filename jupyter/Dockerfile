FROM jupyter:base-image.nix
ENV PATH=/bin
ENTRYPOINT ["/bin/tini", "--"]

RUN mkdir -p /app

WORKDIR /app

COPY requirements.frozen.txt .
RUN pip install -r requirements.frozen.txt --no-cache-dir

COPY src src
COPY setup.py .
RUN pip install --default-timeout=120 -e . --no-cache-dir --no-deps

RUN git config --global user.email "recursive.cookie."

CMD jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root
