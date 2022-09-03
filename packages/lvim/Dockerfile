FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive 
RUN apt update 
RUN apt-get install -y git ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen 

RUN apt-get install -y python3 python3-pip

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /var/tmp/rust-install.sh && sh /var/tmp/rust-install.sh -y 
RUN echo "source $HOME/.cargo/env" >> /root/.bashrc
RUN ln -s /root/.cargo/bin/cargo /usr/local/bin/cargo

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt install -y nodejs
