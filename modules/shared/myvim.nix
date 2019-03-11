{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.myvim;
in

{
  options = {
    programs.myvim.enable = mkOption {
      default = true;
      type = types.bool;
      description = "when enabled, the overlayed neovim is installed";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      my_neovim
    ];

    system.activationScripts.extraUserActivation.text = ''
      (
        set +e
        vim --headless +UpdateRemotePlugins +PlugInstall +qa
      )
    '';
  };
}

