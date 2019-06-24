#! /usr/bin/env bash
set -o pipefail

prog=$0
error() {
   echo "Whoops!  Looks like $1:$2 failed."
   echo "Please try rerunning $prog again."
   exit 1
}
trap 'error "${BASH_SOURCE}" "${LINENO}"' ERR

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" 
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cd $DIR
source utils.sh

check isNonRootUser || exitWithMessage 1 "Do not run as root."

if check fileExists /etc/bash.bashrc; then
  if ! check fileExists /etc/bashrc; then
    echoRun sudo ln -s /etc/bash.bashrc /etc/bashrc
  fi
fi

setupNix
ensureRepo "nix-machines"
ensureOverlay
readyPinned nixos-19.03

nix-build ./nix-up -A installer
exec ./result/bin/up-installer
