{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.nix;
in

{
  imports = [
    ./nix-up.nix
    ./nixpkgs.nix
  ];

  options = {
    nix.package = mkOption {
      type = types.either types.package types.path;
      default = "/nix/var/nix/profiles/default";
      example = "pkgs.nix";
      description = ''
        This option specifies the package or profile that contains the version of Nix to use throughout the system.
      '';
    };

    nix.nixPath = mkOption {
      type = types.listOf types.str;
      default =
        [ # Include default path <up-config>.
          "up=${toString ../..}"
          "up-config=$HOME/.nixpkgs/up-configuration.nix"
          "$HOME/.nix-defexpr/channels"
        ];
      description = ''
        The default Nix expression search path, used by the Nix
        evaluator to look up paths enclosed in angle brackets
        (e.g. <literal>&lt;nixpkgs&gt;</literal>).
      '';
    };
  };

  config = {
    environment.systemPackages = mkIf (isDerivation cfg.package) [ cfg.package ];

    # Set up the environment variables for running Nix.
    environment.variables = { NIX_PATH = concatStringsSep ":" cfg.nixPath; };
  };
}
