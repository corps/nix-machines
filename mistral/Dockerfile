FROM python:3.11
RUN pip install ctransformers==0.2.27 flask
WORKDIR /app
COPY server.py .
CMD python3 server.py
