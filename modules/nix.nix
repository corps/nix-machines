{ config, lib, pkgs, ... }:

with lib;
let compost = import ../compost { inherit pkgs; }; in

{
  imports = [
    ./development.nix
  ];

  config = {
    environment = {
      systemPackages = (if config.environment.development.enable then with pkgs; [
        nixd
        nixfmt-rfc-style
      ] else []) ++ [ compost ];
    };
  
    nix = {
      gc = {
        automatic = true;
        interval = mkIf pkgs.stdenv.isDarwin { Weekday = 0; Hour = 10; Minute = 0; };
        options = "--delete-older-than 14d";
      };
      settings = {
        "extra-experimental-features" = [ "nix-command" "flakes" ];
      };
    };
  };
}
