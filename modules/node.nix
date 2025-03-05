{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.programs.node;
in

{
  imports = [
    ./linked.nix
  ];

  options = {
    programs.node = {
      default = mkOption {
        type = types.package;
        default = pkgs.nodejs-18_x;
        description = "Default node to be provided";
      };

      alternatives = mkOption {
        type = types.attrsOf types.package;
        default = { };
      };
    };
  };

  config = {
    programs.bash.interactiveShellInit = ''
      source <(node --completion-bash)
    '';

    environment = {
      systemPackages = [
        cfg.default
        pkgs.esbuild
      ];

      linked = attrsets.mapAttrsToList (name: value: {
        source = value;
        links = {
          "bin/node" = "bin/node${name}";
        };
      }) cfg.alternatives;
    };
  };
}
