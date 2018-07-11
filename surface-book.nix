{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/wsl
  ];

  environment.systemPackages = with pkgs; [
    nix-repl rip-song ngrok my_neovim fetch_from_github fzy
    universal-ctags ag pkgs.nodePackages.node2nix
    gnupg qrcode-svg fetch_from_pypi git-dropbox wintmp
  ];
}
