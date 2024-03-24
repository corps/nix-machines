FROM python:3.11.8

RUN mkdir /app
WORKDIR /app

COPY requirements.txt .
RUN pip install -r requirements.txt
COPY src /app/src
COPY setup.py .
RUN pip install -e .

EXPOSE 8080
CMD python -m libbiz.server
