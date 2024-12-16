{ pkgs ? import <nixpkgs> {}, writeTextFile ? pkgs.writeTextFile, bring-to-front ? import ./bring-to-front { inherit pkgs; }, writeScript ? pkgs.writeScript, bash ? pkgs.bash }:

window: bin:

let entry = writeScript "btf" ''
#!${bash}/bin/bash

exec ${bring-to-front}/bin/bring-to-front "${window}" "${bin}"
'';

in

writeTextFile {
  name = "btf-${window}.desktop";
  destination = "/share/applications/btf-${window}.desktop";
  text = ''
[Desktop Entry]
Name=Bring To Front ${window}
Type=Application
Exec=${entry}
Terminal=false
'';
}
