# Maps over home manager and darwin attributes to devShell attributes
{
  config,
  lib,
  ...
}:

with lib;
let
  pre-commit-hooks = config.checks.pre-commit-check;
in

{
  imports = [ ./checks.nix ];

  options = rec {
    programs.bash.interactiveShellInit = mkOption {
      type = types.lines;
      default = "";
    };

    environment.systemPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
    };

    buildInputs = environment.systemPackages;
    shellHook = programs.bash.interactiveShellInit;
  };

  config = {
    buildInputs = config.environment.systemPackages ++ pre-commit-hooks.enabledPackages;
    programs.bash.interactiveShellInit = pre-commit-hooks.shellHook;
    shellHook = config.programs.bash.interactiveShellInit;
  };
}
