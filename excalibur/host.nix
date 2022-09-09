{ config, pkgs, ... }:
{
  imports = [ ../modules/nixos/server.nix ../modules/nixos/swarm-host.nix ];
  services.nfs.server.enable = true;
  services.nfs.server.exports = ''
    /export         10.0.0.14(rw,fsid=0,no_subtree_check) 10.0.0.115(rw,fsid=0,no_subtree_check) 10.0.0.45(rw,fsid=0,no_subtree_check)
    /export/data  10.0.0.14(rw,nohide,insecure,no_subtree_check) 10.0.0.115(rw,nohide,insecure,no_subtree_check) 10.0.0.45(rw,nohide,insecure,no_subtree_check)
  '';

  networking.firewall.allowedTCPPorts = [ 111 2049 ];
  networking.firewall.allowedUDPPorts = [ 111 2049 ];
}
