{ config, pkgs, ... }:
{
  imports = [ ../modules/nixos/workstation.nix ];
  networking.firewall.allowedTCPPorts = [ 7100 9323 9100 9700 ];
  programs.steam.enable = true;
}
