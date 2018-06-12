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

  # TODO: Add IgnoreUnknown UseKeychain
  # UseKeychain yes into ssh/config file.  maybe generate them from here.

  system.defaults.dockEx."workspaces-edge-delay" = "0.0";

  environment.systemPackages = with pkgs; [
    nix-repl prettier rip-song ngrok
    jupyter my_neovim fetch_from_github uglifyjs xhelpers autossh fzy
    imagemagick wget universal-ctags ag pkgs.nodePackages.node2nix js-beautify gnupg
    qrcode-svg iterm2 bensrs fetch_from_pypi git-dropbox
  ];

  system.inputPlugins = [ pkgs.canto-input ];

  services.jupyter.enable = true;
  services.tiddly.enable = true;

  nixpkgs.config.vim.ftNix = false;

  nativeApps.vscode.install = true;

  services.khd.khdConfig = ''
    shift + cmd - 0x2C : open -a Webstorm
    shift + cmd - 0x2B : open -a Visual\ Studio\ Code
  '';

  system.symlinks."${home}/.gitconfig" = gitConfig;
  system.symlinks."${home}/Library/Preferences/com.googlecode.iterm2.plist" =
    toString ./dotfiles/com.googlecode.iterm2.plist;

  system.symlinks."${home}/Library/Application\ Support/Code/User/settings.json" =
    toString ./dotfiles/vscode/settings.json;
  system.symlinks."${home}/Library/Application\ Support/Code/User/keybindings.json" =
    toString ./dotfiles/vscode/keybindings.json;
}
