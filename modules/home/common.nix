{ config, lib, pkgs, ... }:

let compost = pkgs.writeScriptBin "compost" ''
#! ${pkgs.bash}/bin/bash
cd $HOME/nix-machines
exec ./home-compost.sh
'';

update-channels = pkgs.writeScriptBin "update-channels" ''
#! ${pkgs.bash}/bin/bash
nix-channel --update
sudo nix-channel --update
'';

unstable = import <unstable> {};
# beancount = unstable.beancount;

in

{
  home.username = "home";
  home.homeDirectory = "/home/home";
 
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = (with pkgs; [
    htop
    add-bin-to-path
    my_neovim
    upgrade-packages
    fetch_from_pypi
    fetch_from_github
    ngrok
    compost
    update-channels
    jq
    docker-compose
    gnumake
    beancount
    bc
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
        hostname = "10.0.0.14";
        user = "home";
      };

      "excalibur" = {
        hostname = "10.0.0.115";
        user = "home";
      };
    };
  };

  # programs.direnv.enable = true;
  # programs.direnv.enableNixDirenvIntegration = true;

  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  # home.stateVersion = "20.03";
}
