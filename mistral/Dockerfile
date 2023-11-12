FROM python:3.11
RUN pip install flask huggingface_hub
WORKDIR /app
COPY server.py .
CMD python3 server.py
