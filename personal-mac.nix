{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/darwin
  ];

  environment.systemPackages = with pkgs; [
    ngrok 
    jupyter 
    imagemagick
    iterm2 
    bensrs 
  ];

  system.inputPlugins = [ pkgs.canto-input ];

  services.khd.khdConfig = ''
    shift + cmd - 0x2C : open -a Webstorm
    shift + cmd - 0x2B : open -a Visual\ Studio\ Code
  '';

  system.symlinks."$HOME/.gitconfig" = ./dotfiles/gitconfig;
  system.symlinks."$HOME/Library/Application\ Support/Code/User/settings.json" =
    toString ./dotfiles/vscode/settings.json;
  system.symlinks."$HOME/Library/Application\ Support/Code/User/keybindings.json" =
    toString ./dotfiles/vscode/keybindings.json;
}
