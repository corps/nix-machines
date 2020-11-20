{ config, pkgs, ... }:

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

in

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = (with pkgs; [
    add-bin-to-path
    htop
    my_neovim
    upgrade-packages
    fetch_from_pypi
    fetch_from_github
    universal-ctags
    nix-pkgs-pinner
    ngrok
    dropbox
    compost
    jq
    clone-all-from
    docker-compose
    gnumake
    postgresql
    ucsf-vpn
    wget
    curl
    update-channels
  ]);

  programs.git = {
    enable = true;
    userName = "Zachary Collins";
    userEmail = "recursive.cookie.jar@gmail.com";
  };

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {};
  };

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.03";
}
