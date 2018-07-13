{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.autohotkey;
  ahk = "$MNTC/Program\ Files/AutoHotkey/AutoHotkey.exe";
  runScript = path:
    "nohup \"${ahk}\" /r $(wintmp ${toString path}) &> /dev/null &";
in

{
  options = {
    programs.autohotkey.scripts = mkOption {
      type = types.listOf types.path;
      default = [];
      description = ".ahk files to load and start on rebuild";
    };

    programs.autohotkey.enable = mkOption {
      default = false;
      type = types.bool;
      description = "when enabled, system activation runs all autohotkey.scripts";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      wintmp
    ];

    system.activationScripts.extraUserActivation.text = 
      "\"${ahk}\" $(wintmp ${toString ./suspend.ahk})\n" +
      (concatStringsSep "\n" (map runScript cfg.scripts));
  };
}

