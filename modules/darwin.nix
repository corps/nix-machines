{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

# let
#   edgeDelay = config.system.defaults.dockEx."workspaces-edge-delay";
#   showWriteDefaults = delay: ''
#       echo Writing worksapces edge delay value
#     	echo defaults write com.apple.dock workspaces-edge-delay -float ${toString delay}
#     	defaults write com.apple.dock workspaces-edge-delay -float ${toString delay}
#   '';
#
# in

{
  imports = [
    {
      _module.args = {
        inherit inputs;
      };
    }
    ./c.nix
    ./libs.nix
    ./nix.nix
    ./node.nix
    ./purescript.nix
    ./python.nix
    ./tools.nix
    ./lean.nix
    ./lua.nix
  ];

  options = {
    system.defaults.dockEx."workspaces-edge-delay" = mkOption {
      default = null;
    };

    programs.git.enable = mkOption {
      default = true;
      type = types.bool;
    };

    programs.git.userName = mkOption {
      default = "Zachary Collins";
      type = types.str;
    };

    programs.git.userEmail = mkOption {
      default = "recursive.cookie.jar@gmail.com";
      type = types.str;
    };
  };

  config = {
    # system.activationScripts.defaults.text = showWriteDefaults
    # (if (isNull edgeDelay) then "0.5" else edgeDelay);
    #
    # system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = 1;
    # system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
    # system.defaults.dock.autohide = true;
    # system.defaults.dock.orientation = "left";
    # system.defaults.finder.AppleShowAllExtensions = true;
    # system.defaults.finder._FXShowPosixPathInTitle = true;
    # system.defaults.dockEx."workspaces-edge-delay" = "0.0";

    fonts.packages = [ pkgs.nerd-fonts.code-new-roman ];
    environment.shells = [ pkgs.bashInteractive ];
    services.skhd.enable = true;
    environment.systemPackages = [ pkgs.starship ] ++ (if config.programs.git.enable then [ pkgs.git ] else [ ]);
    system.activationScripts = mkIf config.programs.git.enable {
      extraUserActivation.text = ''
        git config --global user.name ${config.programs.git.userName}
        git config --global user.email ${config.programs.git.userEmail}
        mkdir -p ~/Library
      '';
    };
  };
}
