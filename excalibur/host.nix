{ pkgs, ... }:
{
  imports = [ ../modules/nixos.nix ];
  networking.firewall.allowedTCPPorts = [ 8991 ];
}
