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

if ! check fileExists /nix; then
  curl https://nixos.org/nix/install | sh
  . $HOME/.nix-profile/etc/profile.d/nix.sh
fi

check existsOnPath nix-env || exitWithMessage 1 "Cannot find nix executables on path."

if ! check fileExists "$HOME/Development/nix-machines"; then
  mkdir -p $HOME/Development
  pushd $HOME/Development
  git clone git@github.com:corps/nix-machines.git
  popd
fi

if ! check fileExists "$HOME/.config/nixpkgs/overlays/nix-machines"; then
  echoRun mkdir -p $HOME/.config/nixpkgs/overlays
  echoRun ln -s $DIR/packages $HOME/.config/nixpkgs/overlays/nix-machines
fi

NIXPKGS_URL=`nix-instantiate --eval --strict --expr 'with (import <nixpkgs> {}); import ./packages/wsl-nixpkgs { inherit lib; }' | sed "s/^\([\"']\)\(.*\)\1\$/\2/g"`
# export NIX_PATH=nixpkgs=$NIXPKGS_URL:$NIX_PATH

nix-build ./nix-wsl -A installer
exec ./result/bin/wsl-installer
