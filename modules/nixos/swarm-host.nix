{ config, lib, pkgs, ... }:
{
  networking.firewall.trustedInterfaces = [ "docker0" "docker_gwbridge" ];
}
