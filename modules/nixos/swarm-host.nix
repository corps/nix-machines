{ config, lib, pkgs, ... }:
{
  networking.firewall.allowedTCPPorts = [ 2377 7946 ];
  networking.firewall.allowedUDPPorts = [ 4789 7946 ];

  fileSystems."/mnt/data" = {
    device = "10.0.0.115:/data";
    fsType = "nfs";
    options = [ "x-systemd.automount" "noauto" ];
  };
}
