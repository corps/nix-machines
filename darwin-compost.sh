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

if ! check fileExists /nix; then
  curl https://nixos.org/nix/install | sh

  if isDarwin; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  else
    . $HOME/.nix-profile/etc/profile.d/nix.sh
  fi
fi

check existsOnPath nix-env || exitWithMessage 1 "Cannot find nix executables on path."

if ! check existsOnPath darwin-rebuild; then
  bash <(curl https://raw.githubusercontent.com/LnL7/nix-darwin/master/bootstrap.sh)
  . /etc/bashrc
fi

if ! check fileExists "$HOME/Development/nix-machines"; then
  mkdir -p $HOME/Development
  pushd $HOME/Development
  git clone git@github.com:corps/nix-machines.git
  popd
fi

if ! check isLink "/etc/nix/nix.conf"; then
  echo -e "$YELLOW /etc/nix/nix.conf is not a link.  sudo rm it and link to /etc/static/nix/nix.conf"
fi

if ! check fileExists "$HOME/.config/nixpkgs/overlays/nix-machines"; then
  mkdir -p $HOME/.config/nixpkgs/overlays
  ln -s $DIR/packages $HOME/.config/nixpkgs/overlays/nix-machines
fi

NIXPKGS_URL=`nix-instantiate --eval --strict --expr 'with (import <nixpkgs> {}); import ./packages/darwin-nixpkgs { inherit lib; }' | sed "s/^\([\"']\)\(.*\)\1\$/\2/g"`

export NIX_PATH=nixpkgs=$NIXPKGS_URL:$NIX_PATH

exec darwin-rebuild switch $@
