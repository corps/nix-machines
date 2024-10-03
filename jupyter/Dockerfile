FROM python:3.11

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    curl \
    tini \
    && rm -rf /var/lib/apt/lists/*

ENTRYPOINT ["/usr/bin/tini", "--"]

RUN mkdir -p /app

WORKDIR /app

COPY requirements.frozen.txt .
RUN pip install -r requirements.frozen.txt --no-cache-dir

COPY src src
COPY setup.py .
RUN pip install --default-timeout=120 -e . --no-cache-dir --no-deps

CMD jupyter notebook --ip=0.0.0.0 --port=8888 --no-browser --allow-root
