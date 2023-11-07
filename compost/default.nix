{ pkgs ? import <nixpkgs> {}, compostScriptPath }:
{
    compost = pkgs.writeScriptBin "compost" ''
#! ${pkgs.bash}/bin/bash
exec ${builtins.toString compostScriptPath}
    '';

    update-channels = pkgs.writeScriptBin "update-channels" ''
#! ${pkgs.bash}/bin/bash
nix-channel --update
sudo nix-channel --update
    '';
}
