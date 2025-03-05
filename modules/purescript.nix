{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.programs.purescript;
  easy-ps = inputs.easy-purescript-nix.packages.${pkgs.system};
in

{
  imports = [
    ./node.nix
  ];

  options = {
    programs.purescript = {
      default = mkOption {
        type = types.package;
        default = easy-ps.purs-0_15_15;
        description = "Default purescript to be provided";
      };
    };
  };

  # Spago isn't building for arm right now, CPU error
  config = mkIf (pkgs.system != "aarch64-darwin") {
    programs.bash.interactiveShellInit = ''
      source <(spago --bash-completion-script `which spago`)
    '';

    environment = {
      systemPackages = [
        cfg.default
        easy-ps.spago
        easy-ps.purescript-language-server
        easy-ps.purs-tidy
      ];
    };
  };
}
