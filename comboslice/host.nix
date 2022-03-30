{ config, pkgs, ... }:

{
  imports = [
    ../modules/nixos/server.nix
  ];

  environment.systemPackages = with pkgs; [ neovim ];
  time.timeZone = "America/Los_Angeles";
  networking.hostName = "comboslice";

  networking.firewall.allowedTCPPorts = [ 23 80 443 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
