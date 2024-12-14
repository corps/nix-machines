{ config, pkgs, ... }:

{
  home.stateVersion = "20.09";
  environment.development.enable = true;

  imports = [ ../modules/home.nix ];
}
