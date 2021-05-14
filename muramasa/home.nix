{ config, pkgs, ... }:
{
  imports = [ ../modules/home/workstation.nix ];
  
  home.stateVersion = "20.03";
}
