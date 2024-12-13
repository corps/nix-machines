{ config, lib, pkgs, ... }:

with lib;

let
edgeDelay = config.system.defaults.dockEx."workspaces-edge-delay";
showWriteDefaults = delay: ''
  echo Writing worksapces edge delay value
	echo defaults write com.apple.dock workspaces-edge-delay -float ${toString delay}
	defaults write com.apple.dock workspaces-edge-delay -float ${toString delay}
'';

in

{
  imports = [ 
    ./c.nix
    ./libs.nix
    ./nix.nix
    ./node.nix
    ./purescript.nix
    ./python.nix
    ./tools.nix
  ];

  options = {
    system.defaults.dockEx."workspaces-edge-delay" = mkOption {
			default = null;
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
  
    environment.shells = [ pkgs.bashInteractive ];
    services.skhd.enable = true;
  };
}
