{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.chocolatey;
in

{
  options = {
    programs.chocolatey.config = mkOption {
      default = "";
      description = "File path to an installation file for chocolatey to process.";
      type = types.string;
    };

    programs.chocolatey.enable = mkOption {
      default = false;
      type = types.bool;
      description = "When enabled, system activation will install the given chocolatey.config file.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wintmp
    ];

    system.activationScripts.extraUserActivation.text = ''
      chocolatey.exe install $(wintmp ${cfg.config})
    '';
  };
}

