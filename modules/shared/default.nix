{ config, lib, pkgs, ... }:

{
  imports = [
    ./software.nix
    ./myvim.nix
    ./nixpkgs.nix
    ./environment.nix
    ./symlinks.nix
    ./user-profile.nix
  ];
}
