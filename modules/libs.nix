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
        (if pkgs.stdenv.isDarwin then lzma else xz)
        openssl
      ] ++ (if config.environment.development.enable then with pkgs; [
        ncurses
      ] else []);
    };
  };
}
