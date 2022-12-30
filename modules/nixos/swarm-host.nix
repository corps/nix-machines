{ config, lib, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [ 2377 7946 ];
  networking.firewall.allowedUDPPorts = [ 4789 7946 ];
  networking.firewall.trustedInterfaces = [ "docker0" "docker_gwbridge" ];
}
