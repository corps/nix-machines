{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.programs.lua;
in

{
  imports = [
    ./linked.nix
    ./development.nix
  ];

  options = {
    programs.lua = {
      default = mkOption {
        type = types.package;
        default = pkgs.lua5_4;
        description = "Default lua to be provided";
      };

      alternatives = mkOption {
        type = types.attrsOf types.package;
        default = { };
      };
    };
  };

  config = {
    environment = {
      systemPackages =
        [
          cfg.default
        ]
        ++ (
          if config.environment.development.enable then
            [
              pkgs.luarocks
            ]
          else
            [ ]
        );

      linked = attrsets.mapAttrsToList (name: value: {
        source = value;
        links = {
          "bin/lua" = "bin/lua${name}";
        };
      }) cfg.alternatives;
    };
  };
}
