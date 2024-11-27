FROM python:3.11.8

RUN apt-get update
RUN apt-get install -y libgomp1 libatlas-base-dev liblapack-dev

RUN mkdir /app
WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt
COPY src /app/src
COPY setup.py .
RUN pip install -e .

COPY start.sh .

RUN useradd --create-home -ms /bin/bash app
RUN mkdir -p /var/fastembed && chown app /var/fastembed
RUN mkdir -p /var/store && chown app /var/store
RUN mkdir -p /var/sqlite/wakimae && chown app /var/sqlite/wakimae
RUN mkdir -p /var/fastembed && chown app /var/fastembed


USER app

EXPOSE 8080
CMD /app/start.sh
