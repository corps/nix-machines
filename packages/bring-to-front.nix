{ wmctrl, writeScriptBin, bash }:

writeScriptBin "bring-to-front" ''
#! ${bash}/bin/bash

PATH=${wmctrl}/bin:$PATH
if (wmctrl -l | grep -c "$1"); then
  wmctrl -a "$1"
else
  nohup "$2" &
fi
''
