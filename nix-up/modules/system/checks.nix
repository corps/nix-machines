{ config, lib, pkgs, ... }:

with lib;

let
  nixChannels = ''
    channelsLink=$(readlink "$HOME/.nix-defexpr/channels") || true
    case "$channelsLink" in
      *"$USER"*)
        ;;
      "")
        ;;
      *)
        echo "[1;31merror: The ~/.nix-defexpr/channels symlink does not point your users channels, aborting activation[0m" >&2
        echo "Running nix-channel will regenerate it" >&2
        echo >&2
        echo "    rm ~/.nix-defexpr/channels" >&2
        echo "    nix-channel --update" >&2
        echo >&2
        exit 2
        ;;
    esac
  '';

  nixInstaller = ''
    if grep -q 'etc/profile.d/nix-daemon.sh' /etc/profile; then
        echo "[1;31merror: Found nix-daemon.sh reference in /etc/profile, aborting activation[0m" >&2
        echo "This will override options like nix.nixPath because it runs later," >&2
        echo "remove this snippet from /etc/profile:" >&2
        echo >&2
        echo "    # Nix" >&2
        echo "    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then" >&2
        echo "      . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'" >&2
        echo "    fi" >&2
        echo "    # End Nix" >&2
        echo >&2
        exit 2
    fi
  '';

  nixPath = ''
    upConfig=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<up-config>' || echo '$HOME/.nixpkgs/up-configuration.nix') || true
    if ! test -e "$upConfig"; then
        echo "[1;31merror: Changed <up-config> but target does not exist, aborting activation[0m" >&2
        echo "Create $upConfig or set nix.nixPath:" >&2
        echo >&2
        echo "    nix.nixPath = [ \"up-config=$(nix-instantiate --eval -E '<up-config>' 2> /dev/null || echo '***')\" ];" >&2
        echo >&2
        exit 2
    fi

    upPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<up>') || true
    if ! test -e "$upPath"; then
        echo "[1;31merror: Changed <up> but target does not exist, aborting activation[0m" >&2
        echo "Add the up repo as a channel or set nix.nixPath:" >&2
        exit 2
    fi

    nixpkgsPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<nixpkgs>') || true
    if ! test -e "$nixpkgsPath"; then
        echo "[1;31merror: Changed <nixpkgs> but target does not exist, aborting activation[0m" >&2
        echo "Add a nixpkgs channel or set nix.nixPath:" >&2
        echo "$ nix-channel --add http://nixos.org/channels/nixpkgs-unstable nixpkgs" >&2
        echo "$ nix-channel --update" >&2
        echo >&2
        echo "or set" >&2
        echo >&2
        echo "    nix.nixPath = [ \"nixpkgs=$(nix-instantiate --eval -E '<nixpkgs>')\" ];" >&2
        echo >&2
        exit 2
    fi
  '';

  nixStore = ''
    if test -w /nix/var/nix/db -a ! -O /nix/store; then
        echo >&2 "[1;31merror: the store is not owned by this user, but /nix/var/nix/db is writable[0m"
        echo >&2 "If you are using the daemon:"
        echo >&2
        echo >&2 "    sudo chown -R /nix/var/nix/db"
        echo >&2
        exit 2
    fi
  '';
in

{
  options = {
  };

  config = {

    system.activationScripts.checks.text = ''
      ${nixStore}
      ${nixChannels}
      ${nixInstaller}
      ${nixPath}
    '';

  };
}
