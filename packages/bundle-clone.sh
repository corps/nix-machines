#! /usr/bin/env bash

set -e

if [ -e $HOME/$1 ]; then
  exit 0;
fi

cd $HOME
git clone $DROPBOX_HOME/git/$1.git $1
cd $1
git remote add -f dropbox "$DROPBOX_HOME/git/$1.git"
git remote rm origin
