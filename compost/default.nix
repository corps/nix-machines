{ pkgs ? import <nixpkgs> {}, bash ? pkgs.bash }:
pkgs.writeScriptBin "compost" ''
#! ${bash}/bin/bash
exec ~/nix-machines/compost/compost.sh
''
