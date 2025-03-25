FROM python:3.12

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
    bash \
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
RUN mkdir /app/data

ENV STUDY_DATA_PATH=/app/data/study.json

CMD python -m ankillio.server
