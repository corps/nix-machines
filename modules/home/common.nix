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
    universal-ctags
    ngrok
    make-tmpfs
    compost
    update-channels
    jq
    clone-all-from
    docker-compose
    gnumake
    postgresql
    beancount
    csvtool
    bc
  ]);

  programs.git = {
    enable = true;
    userName = "Zachary Collins";
    userEmail = "recursive.cookie.jar@gmail.com";

    aliases = {
      bundle-push = "!cd \"$${GIT_PREFIX:-.}\" && if path=\"$(git config remote.\"$1\".url)\" && [ \"$(echo \"$path\" | head -c1)\" = / ]; then git bundle create \"$path\" --all && git fetch \"$1\"; else echo \"Not a bundle remote\"; exit 1; fi #";

      bundle-fetch = "!set -x; cd \"$${GIT_PREFIX:-.}\" && if path=\"$(git config remote.\"$1\".url)\" && [ \"$(echo \"$path\" | head -c1)\" = / ]; then git bundle verify \"$path\" && git fetch \"$1\"; else echo \"Not a bundle remote\"; exit 1; fi #";

      bundle-new = "!cd \"$${GIT_PREFIX:-.}\" && if [ -z \"$${1:-}\" -o -z \"$${2:-}\" ]; then echo \"Usage: git bundle-new <file> <remote name>\"; exit 1; elif [ -e \"$2\" ]; then echo \"File exist\"; exit 1; else git bundle create \"$2\" --all && git remote add -f \"$1\" \"$(realpath \"$2\")\"; fi #";
    };
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

      "cc-dsco1" = {
        hostname = "5.tcp.ngrok.io";
        port = 21171;
        user = "zach";
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
