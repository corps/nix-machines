{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./development.nix
  ];

  config = {
    environment = {
      systemPackages = with pkgs; [
        readline
        xz
        openssl
      ] ++ (if config.environment.development.enable then with pkgs; [
        ncurses
      ] else []);
    };
  };
}
