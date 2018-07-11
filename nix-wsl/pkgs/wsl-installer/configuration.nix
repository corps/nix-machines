{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ <user-wsl-config> ];

  # NOTE: don't set this outside of the installer.
  # users.nix.configureBuildUsers = true;
  # users.knownGroups = [ "nixbld" ];
  # users.knownUsers = [ "nixbld1" "nixbld2" "nixbld3" "nixbld4" "nixbld5" "nixbld6" "nixbld7" "nixbld8" "nixbld9" "nixbld10" ];

  system.activationScripts.preUserActivation.text = mkBefore ''
    wslPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<wsl>' 2> /dev/null) || true

    if ! test -L /etc/bashrc && ! grep -q /etc/static/bashrc /etc/bashrc; then
	echo 'if test -e /etc/static/bashrc; then . /etc/static/bashrc; fi' | sudo tee -a /etc/bashrc
    fi
  '';
}
