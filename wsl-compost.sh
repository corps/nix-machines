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

check isLinux || exitWithMessage 1 "Should only be run in a WSL environment."
check isWsl || exitWithMessage 1 "Should only be run in a WSL environment."
check isNonRootUser || exitWithMessage 1 "Do not run as root."

if ! check existsOnPath choco.exe; then
  echo "Please visit https://chocolatey.org/install and install choco.exe"
  exit 1
fi

if check fileExists /etc/bash.bashrc; then
  if ! check fileExists /etc/bashrc; then
    echoRun sudo ln -s /etc/bash.bashrc /etc/bashrc
  fi
fi

if ! check fileExists /etc/nix/nix.conf; then
  echoRun sudo mkdir -p /etc/nix/
  echoRun sudo cp $DIR/dotfiles/dos.nix.conf /etc/nix/nix.conf
fi

setupNix
ensureRepo "nix-machines"
ensureOverlay
readyPinned nixos-18.09

nix-build ./nix-wsl -A installer
exec ./result/bin/wsl-installer
