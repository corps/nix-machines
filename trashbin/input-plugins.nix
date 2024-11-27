{ config, lib, pkgs, ... }:

with lib;

let
cleanPlugins = ''
  {
    echo "Setting up input plugins."
    cd "/Library/Input Methods"
    for file in $(find ./ -maxdepth 1 -type f -name "*.inputplugin"); do
      echo "Removing $file"
      rm $file
    done
    for file in $(find ./ -maxdepth 1 -type f -name "*.cin"); do
      echo "Removing $file"
      rm $file
    done
  }
'';

updatePlugins = cleanPlugins + (concatStringsSep "\n" (map (dir: ''
  {
    cd "${dir}"
    for file in $(find ./ -maxdepth 1 -type f -name "*.inputplugin"); do
      echo "Installing $file"
      cp ${dir}/$file "/Library/Input Methods/$file"
      open "/Library/Input Methods/$file"
    done
    for file in $(find ./ -maxdepth 1 -type f -name "*.cin"); do
      echo "Installing $file"
      cp ${dir}/$file "/Library/Input Methods/$file"
      open "/Library/Input Methods/$file"
    done
  }
'') config.system.inputPlugins));

in

{
  options = {
    system.inputPlugins = mkOption {
      default = [];
      description = "A list of packages that contain inputplugins in the top directory.";
    };
  };

  config = {
    system.activationScripts.extraActivation.text = updatePlugins;
  };
}
