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
    pre-commit
    direnv
    openssl
    pkg-config
    add-bin-to-path
    watchman
  ];

  environment.shells = [ pkgs.bashInteractive ];
  programs.bash.enable = true;
  programs.bash.enableCompletion = true;

  services.khd.khdConfig = ''
shift + cmd - d : open -a "Firefox"
shift + cmd - e : open -a "alacritty"
shift + cmd - 0x2F : open -a Pycharm
shift + cmd - 0x2C : open -a Pycharm
  '';

  # # system.symlinks."$HOME/.config/alacritty/alacritty.yml" = toString ./dotfiles/alacritty.yml;
  # system.userProfile = ''
  #  ln -s $HOME/.confg/alacritty/alacritty.yml ${./dotfiles/alacritty.yml}
  # '';
}
