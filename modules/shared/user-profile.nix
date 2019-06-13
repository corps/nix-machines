{ config, lib, pkgs, ... }:

with lib;

{
  options = {
    system.userProfile = mkOption {
      default = "";
      description = "";
      type = types.lines;
    };
  };

  config = {
    system.activationScripts.extraUserActivation.text = (builtins.readFile ./user-profile.sh) + ''
      echo "Updating ~/.profile..."
      setUserProfile <<-NONENONEEOM
      ${config.system.userProfile}
      NONENONEEOM
    '';
  };
}
