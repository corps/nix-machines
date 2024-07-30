{ pkgs ? import <nixpkgs> {}, compostScript}:
{
    compost = pkgs.writeScriptBin "compost" ''
#! ${pkgs.bash}/bin/bash
exec ~/nix-machines/compost/${compostScript}
    '';

    update-channels = pkgs.writeScriptBin "update-channels" ''
#! ${pkgs.bash}/bin/bash
nix-channel --update
sudo nix-channel --update
    '';
}
