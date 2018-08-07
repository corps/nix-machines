{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    upgrade-packages
    nix-pkgs-pinner
    nix-repl
    prettier
    rip-song
    fetch_from_github
    uglifyjs
    autossh
    fzy
    wget
    universal-ctags
    ag
    gnupg
    fetch_from_pypi
    git-dropbox
    mitmproxy
  ];

  programs.bash.enable = true;
}
