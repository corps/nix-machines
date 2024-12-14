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
  DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$(cd -P "$(dirname "$SOURCE")" && pwd)"

cd $DIR
source utils.sh

# check isDarwin || exitWithMessage 1 "Should only run on darwin."
check isNonRootUser || exitWithMessage 1 "Do not run as root."

if check isDarwin; then
  if ! check isXcodeInstalled; then
    echo "Xcode installation required.  Rerun $0 when it is complete"
    xcode-select --install
    exit 1
  fi
fi

if ! check fileExists /nix; then
  if isDarwin; then
    sh <(curl https://nixos.org/nix/install) --daemon
    . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
  else
    exitWithMessage 1 "Stop!  compost.sh is currently setup to run on nixos or darwin, not other linux."
  fi
fi

check existsOnPath nix-env || exitWithMessage 1 "Cannot find nix executables on path, something is wrong."

# export NIX_PATH="$HOME/.nix-defexpr/channels:$NIX_PATH"

if isDarwin; then
  if ! check existsOnPath darwin-rebuild; then
    nix run --extra-experimental-features "nix-command flakes" nix-darwin -- switch --flake $DIR/.. $@
  fi

  if ! check shellIs "/run/current-system/sw/bin/bash"; then
    echoRun chsh -s /run/current-system/sw/bin/bash
  fi
else
  echo 1
  # TODO: Install home manager?
  # if ! check existsOnPath home-manager; then
  # fi
fi

if isDarwin; then
  if ! check isLink "/etc/nix/nix.conf"; then
    echo -e "$YELLOW /etc/nix/nix.conf is not a link.  sudo rm it and link to /etc/static/nix/nix.conf"
  fi
fi

if isDarwin; then
  exec darwin-rebuild switch --flake $DIR/.. $@
else
  exec nix run --extra-experimental-features "nix-command flakes" home-manager -- switch --flake $DIR/.. $@
fi
