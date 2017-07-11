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

logWork "Configuring ~/.profile .bash_profile and bashrc..."
touch ~/.profile
addToFile '. $HOME/.nix-profile/etc/profile.d/nix.sh' "$HOME/.profile"
addToFile 'export GTK_IM_MODULE=ibus' "$HOME/.profile"

touch ~/.bash_profile
addToFile '. $HOME/.profile' "$HOME/.bash_profile"
touch ~/.bashrc
addToFile '. $HOME/.profile' "$HOME/.bashrc"

logWork "Checking for nix-machines..."
if [ ! -e "$HOME/Development/nix-machines" ]; then
  mkdir -p $HOME/Development
  pushd $HOME/Development
  git clone git@github.com:corps/nix-machines.git
  popd
fi

if [ ! -e "$HOME/.nixpkgs/config.nix" ]; then
  mkdir -p $HOME/.nixpkgs/
  logWork "Linking config.nix"
  ln -s $HOME/Development/nix-machines/config.nix $HOME/.nixpkgs/config.nix
fi

logWork "Loading nix environment"
. $HOME/.nix-profile/etc/profile.d/nix.sh
