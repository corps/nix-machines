#!@bash@/bin/bash

PATH=@gnutar@/bin:@wget@/bin:$PATH

if [ ! -e $HOME/bin/ngrok ]; then
  mkdir -p $HOME/bin/
  wget "@ngrokUrl@" -O $HOME/bin/ngrok.tgz
  cd $HOME/bin
  tar -xvzf ngrok.tgz
  rm ngrok.tgz
fi

cd $HOME/bin
exec ./ngrok $@
