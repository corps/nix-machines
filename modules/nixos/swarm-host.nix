{ config, lib, pkgs, ... }:
{
  networking.firewall.trustedInterfaces = [ "docker0" "docker_gwbridge" ];
  networking.firewall.allowedTCPPorts = [ 2377 7946 ];
  networking.firewall.allowedUDPPorts = [ 4789 7946 ];
}
