{
  lib,
  pkgs,
  ...
}:

with lib;

let
  ngrok3 = pkgs.callPackage ../ngrok { };
  gdk = pkgs.google-cloud-sdk.withExtraComponents (
    with pkgs.google-cloud-sdk.components;
    [
      gke-gcloud-auth-plugin
    ]
  );
in

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        vim
        neovim
        gnused
        curl
        wget
        jq
        gnumake
        fzf
        starship
        ripgrep
        hub
        ngrok3
        just
        gdk
        gh
        graphite-cli
        gemini-cli
        postgresql
      ];

      variables = {
        # Commit messages and the look should be simple
        EDITOR = "vim";
      };
    };

    programs.bash.enable = true;
    programs.bash.completion.enable = true;
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;
    nixpkgs.config.allowUnfree = true;

    programs.git = {
      enable = true;
      lfs.enable = true;
      userName = "Zachary Collins";
      userEmail = "recursive.cookie.jar@gmail.com";
      extraConfig = {
        protocol.dropbox.allow = "always";
      };
    };

    programs.bash.interactiveShellInit = ''
      HISTSIZE=100000
      HISTFILESIZE=200000

      PROMPT_COMMAND="history -a"
      PROMPT_COMMAND="$PROMPT_COMMAND; history -r"

      # don't put duplicate lines or lines starting with space in the history.
      # See bash(1) for more options
      HISTCONTROL=ignoreboth

      # append to the history file, don't overwrite it
      shopt -s histappend

      # check the window size after each command and, if necessary,
      # update the values of LINES and COLUMNS.
      shopt -s checkwinsize

      # If set, the pattern "**" used in a pathname expansion context will
      # match all files and zero or more directories and subdirectories.
      shopt -s globstar

      eval "$(starship init bash)"
    '';
  };
}
