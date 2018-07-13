{ writeScriptBin, bash }:

writeScriptBin "wintmp" ''
  #! ${bash}/bin/bash

  set -e

  base=$(basename $1)
  hash=$(echo $1 | cksum | cut -f 1 -d ' ')
  tmp=$WINHOME/WinTemp/$base-$hash
  mkdir -p $tmp
  cp $1 $tmp/$base
  wslpath -w $tmp/$base
''
