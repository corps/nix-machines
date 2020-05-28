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

if ! check fileExists ~/.config/nixpkgs/home.nix; then
  if ! check fileExists ~/.nix-defexpr/channels/home-manager; then
    echoRun nix-channel --add https://github.com/rycee/home-manager/archive/release-20.03.tar.gz home-manager
    echoRun nix-channel --update
  fi

  echoRun nix-shell '<home-manager>' -A install
  echoRun ln -sf $DIR/home/home.nix ~/.config/nixpkgs/home.nix
fi

if ! check fileExists ~/.nix-defexpr/channels/unstable; then
  echoRun nix-channel --add https://nixos.org/channels/nixos-unstable unstable
  echoRun nix-channel --update
fi

if ! check fileExists ~/.config/nixpkgs/config.nix; then
  echoRun ln -sf $DIR/home/config.nix ~/.config/nixpkgs/config.nix
fi

if ! check fileExists ~/.profile.nix-machines; then
  echo "source $DIR/home/profile" >> ~/.profile
  touch ~/.profile.nix-machines
fi

if ! check fileExists ~/.bashrc.nix-machines; then
  echo "source $DIR/home/bashrc" >> ~/.bashrc
  touch ~/.bashrc.nix-machines
fi

echoRun ln -sf $DIR/home/Xmodmap ~/.Xmodmap
echoRun ln -sf $DIR/home/xinitrc ~/.xinitrc

echoRun ensureRepo "nix-machines"
echoRun ensureRepo "dotfiles"
echoRun ensureOverlay

echoRun home-manager switch
echoRun sudo nixos-rebuild switch
