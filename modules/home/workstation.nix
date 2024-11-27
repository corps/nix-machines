{ config, pkgs, lib, ... }:

{
  imports = [
    ./common.nix
  ];

  home.packages = (with pkgs; [
  ]);

  programs.firefox = {
    enable = true;
    profiles = {
      myprofile = {
        settings = {
          "general.smoothScroll" = false;
        };
      };
    };
  };
}
