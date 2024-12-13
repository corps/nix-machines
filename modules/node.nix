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
    ./development.nix
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
      systemPackages =
        [
          cfg.default
        ]
        ++ (
          if config.environment.development.enable then
            with pkgs;
            [
              pkgs.esbuild
            ]
          else
            [ ]
        );

      linked = attrsets.mapAttrsToList (name: value: {
        source = value;
        links = {
          "bin/node" = "bin/node${name}";
        };
      }) cfg.alternatives;
    };
  };
}
