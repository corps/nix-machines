{ config, lib, pkgs, ... }:

with lib;
let cfg = config.programs.python; in

{
  imports = [
    ./linked.nix
    ./development.nix
  ];

  options = {
    programs.python = {
      enable = mkOption {
        type = types.boolean;
        default = false;
        description = "enable python environment";
      }
      
      default = mkOption {
        type = types.package;
        default = pkgs.python312;
        description = "Default python to be provided";
      };
      
      alternatives = mkOption {
        type = types.attrsOf types.package;
        default = {
          "3.11" = pkgs.python311;
        };
      };
    }
  };

  config = {
    environment = mkIf cfg.enable {
      systemPackages = [ 
        cfg.default 
      ] ++ (if config.environment.development.enable then [
        cfg.default.pkgs.black
        cfg.default.pkgs.isort
        cfg.default.pkgs.pre-commit-hooks
        cfg.default.pkgs.pip-tools
      ] else []);
      
      linked = mapAttrs' (name: value: { name = "${value}/bin/python${name}"; inherit value; }) cfg.alternatives;
    };
  };
}
