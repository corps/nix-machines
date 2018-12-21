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

if ! check fileExists /nix; then
  sh <(curl https://nixos.org/nix/install) --daemon

  if isDarwin; then
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  else
    . $HOME/.nix-profile/etc/profile.d/nix.sh
  fi
fi

check existsOnPath nix-env || exitWithMessage 1 "Cannot find nix executables on path."

if ! check fileExists "$HOME/Development/nix-machines"; then
  mkdir -p $HOME/Development
  pushd $HOME/Development
  git clone git@github.com:corps/nix-machines.git
  popd
fi

if ! check fileExists "$HOME/.config/nixpkgs/overlays/nix-machines"; then
  mkdir -p $HOME/.config/nixpkgs/overlays
  ln -s $DIR/packages $HOME/.config/nixpkgs/overlays/nix-machines
fi

export PATH=$(nix-build '<nixpkgs>' -A wget --no-out-link --show-trace)/bin/:$PATH

# Check and materialize the pinned nixpkgs cache.
if ! check fileExists ./packages/pinned/nixos-18.09/; then
    (
    set -o pipefail
    set -x
    cd ./packages/pinned
    ref=$(basename "$(readlink ./nixos-18.09)" | cut -d '-' -f 3)
    url=https://github.com/NixOS/nixpkgs-channels/archive/$ref.tar.gz

    wget "$url"
    tar -xzf $ref.tar.gz

    rm $ref.tar.gz
    )
fi

if ! check fileExists ~/.nix-defexpr/channels/nixpkgs; then
  nix-channel --add http://nixos.org/channels/nixpkgs-unstable nixpkgs
  nix-channel --update
fi

export NIX_PATH=nixpkgs=$DIR/packages/pinned/nixos-18.09:$NIX_PATH
nix-build ./nix-up -A installer
exec ./result/bin/up-installer
