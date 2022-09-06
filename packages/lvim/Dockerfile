FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive 
RUN apt update 
RUN apt-get install -y git ninja-build gettext libtool libtool-bin autoconf automake cmake g++ pkg-config unzip curl doxygen 

RUN apt-get install -y python3 python3-pip


RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash -
RUN apt install -y nodejs

RUN curl -s https://raw.githubusercontent.com/lunarvim/lunarvim/master/utils/installer/install.sh > /bin/install-lvim
RUN chmod +x /bin/install-lvim


RUN apt-get install -y software-properties-common
RUN add-apt-repository ppa:neovim-ppa/stable
RUN apt-get update
RUN apt-get install -y neovim

ARG userid=1000
RUN useradd -ms /bin/bash -u $userid lvim

USER lvim
WORKDIR /home/lvim
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs -o /var/tmp/rust-install.sh && sh /var/tmp/rust-install.sh -y 
RUN echo "source /home/lvim/.cargo/env" >> /home/lvim/.bashrc

RUN /bin/install-lvim -y
