{ config, lib, pkgs, ... }:

let
compostPkgs = (import ../../compost) { inherit pkgs; compostScript = "home-compost.sh"; };

in

{
  home.username = "home";
  home.homeDirectory = "/home/home";

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = (with pkgs; with compostPkgs; [
    nixfmt-rfc-style
    compost
    update-channels
    jq
    gnumake
  ]);

  programs.git = {
    enable = true;
    userName = "Zachary Collins";
    userEmail = "recursive.cookie.jar@gmail.com";
  };

  programs.chromium = {
    enable = true;
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "comboslice" = {
        hostname = "10.0.0.45";
        user = "home";
      };

      "excalibur" = {
        hostname = "10.0.0.115";
        user = "home";
      };
    };
  };

  programs.direnv.enable = true;
  # programs.direnv.enableNixDirenvIntegration = true;

  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  # home.stateVersion = "20.03";
}
