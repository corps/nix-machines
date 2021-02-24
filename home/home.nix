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
webstorm = unstable.jetbrains.webstorm;
ruby-mine = unstable.jetbrains.ruby-mine;
datagrip = unstable.jetbrains.datagrip;
pycharm = unstable.jetbrains.pycharm-professional;
act = unstable.act;
bring-firefox-to-front = pkgs.bring-to-front-desktop "Firefox" "${pkgs.firefox}/bin/firefox";
bring-konsole-to-front = pkgs.bring-to-front-desktop "Konsole" "${pkgs.konsole}/bin/konsole";
bring-webstorm-to-front = pkgs.bring-to-front-desktop "webstorm-proj" "${webstorm}/bin/webstorm";
bring-rubymine-to-front = pkgs.bring-to-front-desktop "ruby-mine-proj" "${ruby-mine}/bin/ruby-mine";
bring-datagrip-to-front = pkgs.bring-to-front-desktop "datagrip-proj" "${datagrip}/bin/datagrip";
bring-pycharm-to-front = pkgs.bring-to-front-desktop "pycharm-proj" "${pycharm}/bin/pycharm-professional";
chefdk = unstable.chefdk;
# beancount = unstable.beancount;

in

{
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
    nix-pkgs-pinner
    ngrok
    bring-to-front
    make-tmpfs
    dropbox
    compost
    update-channels
    signal-desktop
    bring-firefox-to-front
    bring-konsole-to-front
    bring-webstorm-to-front
    bring-rubymine-to-front
    bring-datagrip-to-front
    bring-pycharm-to-front
    pycharm
    webstorm
    ruby-mine
    datagrip
    jq
    clone-all-from
    docker-compose
    gnumake
    zoom-us
    postgresql
    ucsf-vpn
    act
    kazam
    make-splits
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

  services.gpg-agent = {
    enable = true;
    defaultCacheTtl = 1800;
    enableSshSupport = true;
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "cbc-master timur magma janus metis archimedes magma-stage metis-stage timur-stage archimedes-stage janus-stage iliad iliad-stage" = {
        hostname = "%h.ucsf.edu";
        user = "zcollins";
      };

      "cbc-support" = {
        hostname = "%h.ucsf.edu";
        user = "zcollins";
      };
      
      "comboslice" = {
        hostname = "10.0.0.14";
        user = "home";
      };

      "cc-dsco1" = {
        hostname = "169.230.134.238";
        user = "zach";
      };
    };
  };

  programs.vscode = {
    enable = true;
    userSettings = lib.importJSON ../dotfiles/settings.json;
    keybindings = lib.importJSON ../dotfiles/keybindings.json;
    extensions = [ 
      unstable.vscode-extensions.vscodevim.vim 
    ];
  };

  programs.direnv.enable = true;
  programs.direnv.enableNixDirenvIntegration = true;

  # This value determines the Home Manager release that your
  # configuration is compatible with. This helps avoid breakage
  # when a new Home Manager release introduces backwards
  # incompatible changes.
  #
  # You can update Home Manager without changing this value. See
  # the Home Manager release notes for a list of state version
  # changes in each release.
  home.stateVersion = "20.03";
}
