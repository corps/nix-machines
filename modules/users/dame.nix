{ config, lib, pkgs, ... }:
{
  users.extraUsers.dame = {
    isNormalUser = true;
    uid = 1000;
    extraGroups = ["wheel" "networkmanager"];
    openssh.authorizedKeys.keys = (import ../../authorized-keys.nix).github.corps;
  };
}
