 { config, pkgs, lib, ... }:

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
  options = {
    system.defaults.dockEx."workspaces-edge-delay" = mkOption {
			default = null;
    };
  };


  config = {
    system.activationScripts.defaults.text = showWriteDefaults
		  (if (isNull edgeDelay) then "0.5" else edgeDelay);
  };
}
