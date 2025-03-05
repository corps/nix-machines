{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.programs.python;
in

{
  imports = [
    ./linked.nix
    ./checks.nix
  ];

  options = {
    programs.python = {
      default = mkOption {
        type = types.package;
        default = pkgs.python312;
        description = "Default python to be provided";
      };

      alternatives = mkOption {
        type = types.attrsOf types.package;
        default = { };
      };
    };
  };

  config = {
    environment = {
      systemPackages = [
        cfg.default
        cfg.default.pkgs.black
        cfg.default.pkgs.isort
        cfg.default.pkgs.pip-tools
      ];

      linked = attrsets.mapAttrsToList (name: value: {
        source = value;
        links = {
          "bin/python" = "bin/python${name}";
        };
      }) cfg.alternatives;
    };

    hooks.settings = {
      black.enable = true;
      isort.enable = true;
      isort.settings.profile = "black";
    };
  };
}
