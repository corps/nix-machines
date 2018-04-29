#!@bash@/bin/bash

PATH=@unzip@/bin:@wget@/bin:$PATH

if [ ! -e $HOME/bin/ngrok ]; then
  mkdir -p $HOME/bin/
  wget "@ngrokUrl@" -O $HOME/bin/ngrok.zip
  cd $HOME/bin
  unzip ngrok.zip
  rm ngrok.zip
fi

cd $HOME/bin
exec ./ngrok $@
