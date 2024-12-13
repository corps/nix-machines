{ config, lib, pkgs, ... }:

with lib;
let cfg = config.environment.development; in

{
  imports = [
    ./linked.nix
  ];

  options = {
    environment.development = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "enable common development environment tools";
      };
    };
  };

  config = {
    environment = mkIf cfg.enable {
      systemPackages = with pkgs; [ 
        ripgrep
        watchman
        pre-commit
      ];
    };
  };
}
