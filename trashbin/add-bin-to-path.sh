#! /usr/bin/env bash

if [[ -z "$1" ]]; then
  exit
fi

bin=$(readlink -f $1)
tmp=$(mktemp)

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
