{ config, lib, pkgs, ... }:

{
  imports = [ ./modules/darwin ];

  environment.systemPackages = with pkgs; [
    nix-repl prettier rip-song
    jupyter my_neovim fetch_from_github uglifyjs xhelpers autossh fzy
    imagemagick wget universal-ctags ag pkgs.nodePackages.node2nix js-beautify gnupg
    qrcode-svg
  ];

  services.jupyter.enable = true;
  nixpkgs.config.vim.ftNix = false;
}
