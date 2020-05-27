{ config, pkgs, ... }:

let compost = pkgs.writeScriptBin "compost" ''
#! ${pkgs.bash}/bin/bash
cd $HOME/nix-machines
exec ./home-compost.sh
'';

in

{
  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    htop
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
  ];

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
