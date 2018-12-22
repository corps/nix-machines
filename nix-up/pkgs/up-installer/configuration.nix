{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ <user-up-config> ];

  # NOTE: don't set this outside of the installer.
  # users.nix.configureBuildUsers = true;
  # users.knownGroups = [ "nixbld" ];
  # users.knownUsers = [ "nixbld1" "nixbld2" "nixbld3" "nixbld4" "nixbld5" "nixbld6" "nixbld7" "nixbld8" "nixbld9" "nixbld10" ];

  system.activationScripts.preUserActivation.text = mkBefore ''
    upPath=$(NIX_PATH=${concatStringsSep ":" config.nix.nixPath} nix-instantiate --eval -E '<up>' 2> /dev/null) || true

    if ! test -L /etc/profile.d/nix.sh && ! grep -q /etc/static/bashrc /etc/profile.d/nix.sh; then
      echo 'if test -e /etc/static/bashrc; then . /etc/static/bashrc; fi' | sudo tee -a /etc/profile.d/nix.sh
    fi
  '';
}
