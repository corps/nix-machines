#!/usr/bin/env bash

set -x
set -e
set -u
set -o pipefail

function logError {
  echo -e "\033[1;31m$1\033[0m"
}

function logSuccess {
  echo  -e "\033[1;32m$1\033[0m"
}

function logWork {
  echo -e "\033[1;36m$1\033[0m"
}

function addToFile {
  grep -qF "$1" "$2" || echo "$1" >> "$2"
}

if [[ $EUID -eq 0 ]]; then
  logError "You cannot run this script as root.  Please run it as your main user."
  exit 1
fi


logWork "Checking nix installation"
if [ ! -e "/nix" ]; then
  logWork "Installing nix, this will take awhile."
  curl https://nixos.org/nix/install | sh
fi

logWork "Configuring ~/.profile..."
touch ~/.profile
addToFile ". /Users/dame/.nix-profile/etc/profile.d/nix.sh" "$HOME/.profile"
addToFile "export NIX_PATH=corpkgs=$HOME/Development/nix-machines/packages:$NIX_PATH" "$HOME/.profile"

if [ ! -e "$HOME/.nixpkgs/" ]; then
  mkdir -p $HOME/.nixpkgs/
  logWork "Configuring ~/.nixpkgs/config.nix..."
  echo "{ allowUnfree = true; }" > $HOME/.nixpkgs/config.nix
fi

logWork "Checking for nix-machines..."
if [ ! -e "$HOME/Development/nix-machines" ]; then
  mkdir -p $HOME/Development
  pushd $HOME/Development
  git clone git@github.com:corps/nix-machines.git
  popd
fi

logWork "Loading nix environment"
. $HOME/.nix-profile/etc/profile.d/nix.sh
