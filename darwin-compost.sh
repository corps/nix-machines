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

check isDarwin || exitWithMessage 1 "Should only run on darwin."
check isNonRootUser || exitWithMessage 1 "Do not run as root."

if ! check isXcodeInstalled; then
  echo "Xcode installation required.  Rerun $0 when it is complete";
  xcode-select --install
  exit 1
fi

setupNix

HOME_NIX=${HOME_NIX-:$DIR/home/home.nix}
export NIX_PATH="$HOME/.nix-defexpr/channels:$NIX_PATH"

if ! check existsOnPath darwin-rebuild; then
  nix-build https://github.com/LnL7/nix-darwin/archive/master.tar.gz -A installer
  ./result/bin/darwin-installer
  . /etc/bashrc
fi

if ! check isLink "/etc/nix/nix.conf"; then
  echo -e "$YELLOW /etc/nix/nix.conf is not a link.  sudo rm it and link to /etc/static/nix/nix.conf"
fi

ensureOverlay

if ! check fileExists ~/.profile.nix-machines; then
  echo "source $DIR/dotfiles/profile" >> ~/.profile
  echo "export HOME_NIX='$HOME_NIX'" >> ~/.profile
  echo "export NO_REBUILD=$NO_REBUILD" >> ~/.profile
  touch ~/.profile.nix-machines
fi

if ! check fileExists ~/.bashrc.nix-machines; then
  echo "source $DIR/dotfiles/bashrc" >> ~/.bashrc
  echo "export HOME_NIX='$HOME_NIX'" >> ~/.bashrc
  echo "export NO_REBUILD=$NO_REBUILD" >> ~/.bashrc
  touch ~/.bashrc.nix-machines
fi

export NIX_PATH=darwin-config=$HOME/.nixpkgs/darwin-configuration.nix:$NIX_PATH
export NIX_PATH=$NIX_PATH:$HOME/.nix-defexpr/channels
exec darwin-rebuild switch $@
