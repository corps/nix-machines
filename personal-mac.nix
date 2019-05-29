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

  system.inputPlugins = [ pkgs.canto-input ];

  services.khd.khdConfig = ''
    shift + cmd - 0x2C : open -a Webstorm
    shift + cmd - 0x2B : open -a Visual\ Studio\ Code
    shift + cmd - 0x25 : open -a stickies
    shift + cmd - 0x28 : open -a nvALT
  '';

  system.symlinks."$HOME/.gitconfig" = ./dotfiles/gitconfig;
  system.symlinks."$HOME/Library/Application\ Support/Code/User/settings.json" =
    toString ./dotfiles/vscode/settings.json;
  system.symlinks."$HOME/Library/Application\ Support/Code/User/keybindings.json" =
    toString ./dotfiles/vscode/keybindings.json;
  system.symlinks."$HOME/.config/alacritty/alacritty.yml" = toString ./dotfiles/alacritty.yml;
}
