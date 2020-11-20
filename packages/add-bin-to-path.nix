{ pkgs ? import <nixpkgs> {}
, writeScriptBin ? pkgs.writeScriptBin
}:

writeScriptBin "add-bin-to-path" (builtins.readFile ./add-bin-to-path.sh)
