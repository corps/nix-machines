{ config, pkgs, ... }:
{
  imports = [ ../modules/nixos/server.nix ../modules/nixos/swarm-host.nix ];
}
