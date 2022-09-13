{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/darwin
  ];

  environment.systemPackages = with pkgs; [
    ngrok
    my_neovim
    activate-window
    bash
    nnn
    git
    runc
    gnused
  ];

  environment.shells = [ pkgs.bashInteractive ];
  programs.bash.enable = true;
  programs.bash.enableCompletion = true;

  # # system.symlinks."$HOME/.config/alacritty/alacritty.yml" = toString ./dotfiles/alacritty.yml;
  # system.userProfile = ''
  #  ln -s $HOME/.confg/alacritty/alacritty.yml ${./dotfiles/alacritty.yml}
  # '';
}
