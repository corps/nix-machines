# Maps over home manager and darwin attributes to devShell attributes
{
  config,
  lib,
  ...
}:

with lib;

{
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
    buildInputs = config.environment.systemPackages;
    shellHook = config.programs.bash.interactiveShellInit;
  };
}
