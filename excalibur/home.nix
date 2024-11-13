{ config, pkgs, ... }:

let unstable = import <unstable> {}; in

{
  imports = [ ../modules/home/workstation.nix ];
  
  home.packages = with unstable; [
    (jetbrains.plugins.addPlugins jetbrains.pycharm-professional [ "nixidea" "ideavim" ])
  ];
  home.stateVersion = "20.09";
}
