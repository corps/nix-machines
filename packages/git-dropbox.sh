#! /usr/bin/env bash

set -e
set -o pipefail

DROPBOX_DIR=$HOME/Dropbox
DROPBOX_GIT_DIR=$DROPBOX_DIR/git


function usage {
  echo "Usage: $(basename $0) init|clone|ls [<repo-name>]" >&2
}

if [[ ! -e $DROPBOX_GIT_DIR ]]; then
  echo "Could not find dropbox directory." >&2
fi

if [[ -z $1 ]]; then
  usage
  exit 1
fi

orig=$PWD

case $1 in
  init)
    if [[ -z $2 ]]; then
      usage
      exit 1
    fi

    set -x
    if [[ ! -e .git ]]; then
      git init
    fi

    cd $DROPBOX_GIT_DIR
    git init --bare $2.git

    cd $orig
    git remote add origin $DROPBOX_GIT_DIR/$2.git
    ;;

  clone)
    if [[ -z $2 ]]; then
      usage
      exit 1
    fi

    set -x
    git clone $DROPBOX_GIT_DIR/$2.git
    ;;

  ls)
    ls $DROPBOX_GIT_DIR
    ;;
esac
