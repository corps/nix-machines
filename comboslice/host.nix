{ config, pkgs, ... }:

{
  imports = [
    ../modules/nixos/server.nix
  ];

  # environment.systemPackages = with pkgs; [ neovim ];
  # time.timeZone = "America/Los_Angeles";
  # networking.hostName = "comboslice";

  # networking.firewall.allowedTCPPorts = [ 53 ];
  # networking.firewall.allowedUDPPorts = [ 53 ];
  services.gpm.enable = true;
}
