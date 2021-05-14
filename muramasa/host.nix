{ config, pkgs, ... }:
{
  imports = [ ../modules/nixos/workstation.nix ];
  networking.wireless = {
    enable = true;
    userControlled.enable = true;
  };
  networking.firewall.allowedTCPPorts = [];
}
