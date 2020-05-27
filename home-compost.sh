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
    nix-channel --add https://github.com/rycee/home-manager/archive/release-20.03.tar.gz home-manager
    nix-channel --update
  fi

  nix-shell '<home-manager>' -A install
  echoRun ln -sf $DIR/home/home.nix ~/.config/nixpkgs/home.nix
fi

ensureRepo "nix-machines"
ensureRepo "dotfiles"
ensureOverlay

home-manager switch
