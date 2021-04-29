{ config, pkgs, ... }:
{
  imports = [ ../modules/home/server.nix ];
  
  home.stateVersion = "20.03";
}
