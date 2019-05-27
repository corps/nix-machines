{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/darwin
  ];

  environment.systemPackages = with pkgs; [
    ngrok
    jupyter
    imagemagick
    bensrs
  ];

  services.khd.khdConfig = ''
    shift + cmd - 0x29 : open -a Slack
    shift + cmd - 0x2C : open -a Webstorm
    shift + cmd - 0x2F : open -a Pycharm
    shift + cmd - 0x2B : open -a PyCharm\ CE
  '';

  system.inputPlugins = [ pkgs.canto-input ];

  system.symlinks."$HOME/.gitconfig" = ./dotfiles/gitconfig;
  system.symlinks."$HOME/Library/Application\ Support/Code/User/settings.json" =
    toString ./dotfiles/vscode/settings.json;
  system.symlinks."$HOME/Library/Application\ Support/Code/User/keybindings.json" =
    toString ./dotfiles/vscode/keybindings.json;
}
