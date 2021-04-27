{ config, pkgs, lib, ... }:
let
unstable = import <unstable> {};
in

{
  imports = [
    ./common.nix
  ];

  home.packages = (with pkgs; [
  ]);
}
