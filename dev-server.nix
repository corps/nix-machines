{ config, lib, pkgs, ... }:
{
  imports = [
    ./modules/nixos/nixpkgs.nix
    ./modules/nixos/networking.nix
    ./modules/nixos/software.nix
    ./modules/nixos/ssh.nix
    ./modules/nixos/xserver.nix
    ./modules/nixos/fonts.nix
    ./modules/nixos/input-methods.nix
    ./modules/nixos/audio.nix
    ./modules/nixos/dame.nix
  ];

  time.timeZone = "Asia/Tokyo";
}
