{ config, lib, pkgs, ... }:

with lib;

let

activateSymLinks = links: (builtins.readFile ./update-symlinks.sh) + (concatStringsSep "\n"
(mapAttrsToList (dest: src: "update_symlink \"${src}\" \"${dest}\"") links));

in

{
  options = {
    system.symlinks = mkOption {
      default = {};
      description = "An attrset of dest -> src paths to link";
    };
  };

  config = {
    system.activationScripts.extraUserActivation.text = activateSymLinks config.system.symlinks;
  };
}
