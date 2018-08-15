{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    upgrade-packages
    nix-pkgs-pinner
    rip-song
    fetch_from_github
    nodeTools
    autossh
    fzy
    wget
    universal-ctags
    ag
    gnupg
    fetch_from_pypi
    git-dropbox
  ];

  programs.bash.enable = true;
}
