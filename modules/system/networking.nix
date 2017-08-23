{ config, lib, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [ 5900 ];
  networking.hostName = "hotdog";
  services.avahi = {
    enable = true;
    hostName = "hotdog";
    nssmdns = true;
    publish = {
      enable = true;
      domain = true;
      addresses = true;
    };
  };
}
