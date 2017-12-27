{ config, lib, pkgs, ... }:

let

home = "/Users/zachcollins";
gitConfig = builtins.toFile "gitconfig" ''
[user]
	name = Zach Collins
	email = recursive.cookie.jar@gmail.com
'';

in

{
  imports = [
    ./modules/darwin
  ];

  system.defaults.dockEx."workspaces-edge-delay" = "0.0";

  environment.systemPackages = with pkgs; [
    nix-repl prettier rip-song ngrok
    jupyter my_neovim fetch_from_github uglifyjs xhelpers autossh fzy
    imagemagick wget universal-ctags ag pkgs.nodePackages.node2nix js-beautify gnupg
    qrcode-svg iterm2 bensrs
  ];

  system.inputPlugins = [ pkgs.canto-input ];

  services.jupyter.enable = true;
  # services.chunkwm.enable = true;

  nixpkgs.config.vim.ftNix = false;

  system.symlinks."${home}/.gitconfig" = gitConfig;
  system.symlinks."${home}/Library/Preferences/com.googlecode.iterm2.plist" = ./dotfiles/com.googlecode.iterm2.plist;
}
