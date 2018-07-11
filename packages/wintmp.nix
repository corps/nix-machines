{ writeScriptBin, bash }:

writeScriptBin "wintmp" ''
  #! ${bash}/bin/bash

  set -e

  base=$(basename $1)
  tmp=$WINHOME/WinTemp
  mkdir -p $tmp
  tmp=$(mktemp -p "$tmp" -d)
  cp $1 $tmp/$base
  wslpath -w $tmp/$base
''
