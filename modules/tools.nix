{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  ngrok3 = pkgs.callPackage ../ngrok { };
in

{
  imports = [
    ./development.nix
  ];

  config = {
    environment = {
      systemPackages =
        with pkgs;
        [
          vim
          neovim
          gnused
          curl
          wget
        ]
        ++ (
          if config.environment.development.enable then
            with pkgs;
            [
              hub
              ngrok3
            ]
          else
            [ ]
        );

      variables = {
        EDITOR = "vim";
      };
    };

    programs.bash.enable = true;
    programs.bash.completion.enable = true;
    programs.direnv.enable = true;
    programs.direnv.nix-direnv.enable = true;

    programs.git = {
      enable = true;
      userName = "Zachary Collins";
      userEmail = "recursive.cookie.jar@gmail.com";
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
    '';
  };
}
