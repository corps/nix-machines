{ config, pkgs, lib, ... }:

{
  imports = [
    ./common.nix
  ];

  home.packages = (with pkgs; [
  ]);
}
