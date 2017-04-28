{ config, lib, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [ 5900 ];
  networking.hostName = "hotdog";
}
