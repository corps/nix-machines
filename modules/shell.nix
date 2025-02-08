{ config, lib, pkgs, ... }:

with lib;

{
  imports = [
    ./linked.nix
    ./development.nix
  ];

  options = rec {
    programs.bash.interactiveShellInit = mkOption {
        type = types.lines;
        default = "";
    };

    environment.systemPackages = mkOption {
        type = types.listOf types.package;
        default = [];
    };

    buildInputs = environment.systemPackages;
    shellHook = programs.bash.interactiveShellInit;
  };

  config = {
    buildInputs = config.environment.systemPackages;
    shellHook = config.programs.bash.interactiveShellInit;
  };
}
