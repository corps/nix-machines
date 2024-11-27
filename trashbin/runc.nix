{ pkgs ? import <nixpkgs> {}
, writeScriptBin ? pkgs.writeScriptBin
, gnused ? pkgs.gnused
, gcc ? pkgs.gcc
}:

writeScriptBin "runc" ''
${gnused}/bin/sed -n '2,$p' "$@" | ${gcc}/bin/gcc -o /tmp/a.out -x c++ - && /tmp/a.out
rm -f /tmp/a.out
''
