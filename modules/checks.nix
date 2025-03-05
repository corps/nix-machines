{
  lib,
  inputs,
  pkgs,
  config,
  ...
}:

with lib;

{

  options = {
    hooks.src = mkOption {
      type = types.path;
      default = ../.;
      description = "Directory to apply hooks to.";
    };

    hooks.settings = mkOption {
      type = types.attrs;
      default = {
      };
      description = "settings to pass to pre-commit-checks";
    };

    checks = mkOption {
      type = types.attrsOf types.package;
    };
  };

  config = {
    checks.pre-commit-check = inputs.pre-commit-hooks.lib.${pkgs.system}.run {
      src = config.hooks.src;
      hooks = config.hooks.settings;
    };

    hooks.settings = {
      check-case-conflicts.enable = true;
      check-merge-conflicts.enable = true;
      check-yaml.enable = true;
      detect-private-keys.enable = true;
      end-of-file-fixer.enable = true;
      trim-trailing-whitespace.enable = true;
    };
  };
}
