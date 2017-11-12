{ config, lib, pkgs, ... }:

{
  imports = [ ./modules/darwin ];

  environment.systemPackages = with pkgs; [ 
    nix-repl prettier
    jupyter my_neovim fetch_from_github uglifyjs xhelpers corpscripts autossh fzy
    imagemagick wget universal-ctags ag
  ];

  services.jupyter.enable = true;
  nixpkgs.config.vim.ftNix = false;
}
