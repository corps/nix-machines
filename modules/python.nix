{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.programs.python;
  git-remote-dropbox = cfg.default.pkgs.buildPythonPackage rec {
    pname = "git-remote-dropbox";
    version = "2.0.5";
    pyproject = true;

    src = pkgs.fetchFromGitHub {
      owner = "anishathalye";
      repo = "git-remote-dropbox";
      tag = "v${version}";
      hash = "sha256-Bv9+lZCZia+ZhcXOnzD1kz0KIbwkcS2gqG2C4J0Kp7Q=";
    };

    build-system = [
      cfg.default.pkgs.hatchling
      cfg.default.pkgs.flit-core
    ];

    dependencies = [
      cfg.default.pkgs.dropbox
    ];
  };
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
        git-remote-dropbox
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
