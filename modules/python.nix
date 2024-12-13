{ config, lib, pkgs, ... }:

with lib;

let
cfg = config;
in

{
  options = {
    programs.python.enable = mkOption {
      type = types.boolean;
      default = false;
      description = "enable python environment";
    }
    programs.python.default = mkOption {
      type = types.package;
      default = pkgs.python311;
      description = "Default python to be provided";
    };
    programs.python.alternatives = mkOption {
      type = types.attrsOf types.package;
      default = {
          "3.12" = pkgs.python312;
      };
    }
  };

  config = {
    environment.systemPackages = []
  };
}
