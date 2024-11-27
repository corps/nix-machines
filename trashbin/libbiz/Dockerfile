FROM python:3.11.8

RUN mkdir /app
WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt
COPY src /app/src
COPY setup.py .
RUN pip install -e .

COPY start.sh .

EXPOSE 8080
CMD /app/start.sh
