FROM node:22

RUN mkdir -p /app
WORKDIR /app

COPY package.json .
COPY package-lock.json .
RUN npm install

COPY output output
COPY dist dist
