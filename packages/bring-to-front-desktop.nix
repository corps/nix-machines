{ writeTextFile, bring-to-front, writeScript, bash }:

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
