{ config, pkgs, ... }:
{
  imports = [ ../modules/nixos/workstation.nix ];
  networking.firewall.allowedTCPPorts = [ 7100 9323 9100 ];
}
