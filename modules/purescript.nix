{ inputs ? {}, easy-ps ? inputs.easy-purescript-nix.packages.${pkgs.system}, config, lib, pkgs, ... }:

with lib;
let cfg = config.programs.purescript; in

{
  imports = [
    ./node.nix
    ./development.nix
  ];

  options = {
    programs.purescript = {
      enable = mkOption {
        type = types.bool;
        default = false;
        description = "enable purescript environment";
      };
      
      default = mkOption {
        type = types.package;
        default = easy-ps.purs-0_15_15;
        description = "Default purescript to be provided";
      };
    };
  };

  config = mkIf cfg.enable {
    programs.bash.interactiveShellInit = if config.environment.development.enable then ''
      source <(spago --bash-completion-script `which spago`)
    '' else "";
    
    environment = {
      systemPackages = (if config.environment.development.enable then [
        cfg.default 
        easy-ps.spago
        easy-ps.purescript-language-server
        easy-ps.purs-tidy
      ] else []);
    };
  };
}
