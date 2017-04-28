{ config, lib, pkgs, ... }:
{
  imports = [
    ./modules/system/networking.nix
    ./modules/system/software.nix
    ./modules/system/ssh.nix
    ./modules/system/xserver.nix
    ./modules/users/dame.nix
  ];
}