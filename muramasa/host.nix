{ config, pkgs, ... }:
{
  imports = [ ../modules/nixos/workstation.nix ];
  networking.firewall.allowedTCPPorts = [];
}
