{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/darwin/nixpkgs.nix
    ./modules/darwin/common.nix
  ];

  environment.systemPackages = with pkgs; [ 
    nix-repl prettier
    jupyter my_neovim fetch_from_github uglifyjs xhelpers corpscripts autossh fzy
    imagemagick wget universal-ctags ag
  ];

  nixpkgs.config.vim.ftNix = false;
}
