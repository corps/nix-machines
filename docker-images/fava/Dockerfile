FROM ubuntu:latest
RUN apt-get -y update && apt-get install -y python3-dev python3-pip && pip3 install beancount fava
ENV LC_ALL=C.UTF-8
ENV LANG=C.UTF-8
COPY run-fava.sh /run-fava.sh
EXPOSE 5000
CMD /run-fava.sh
