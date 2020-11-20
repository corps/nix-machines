#! /usr/bin/env bash

bin=$1
tmp=$(mktemp)

if [[ -z "$bin" ]]; then
  exit
fi

bname=$(basename $bin)


echo "
{ pkgs ? import <nixpkgs> {}
, writeScriptBin ? pkgs.writeScriptBin 
}:
writeScriptBin \"${bname}\" ''
#! /usr/bin/env bash
exec ${bin} \$@
''
" > $tmp

exec nix-env -i --file $tmp
