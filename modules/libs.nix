{
  lib,
  pkgs,
  ...
}:

with lib;

{
  config = {
    environment = {
      systemPackages = with pkgs; [
        readline
        xz
        openssl
        ncurses
      ];
    };
  };
}
