{ config, pkgs, ... }:
{
  imports = [ ../modules/home/workstation.nix ];
  
  home.stateVersion = "20.03";
  home.packages = with pkgs; [
    browsh
  ];
}
