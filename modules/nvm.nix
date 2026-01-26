{
  pkgs ? import <nixpkgs>,
  writeShellScript ? pkgs.writeShellScript,
}:
writeShellScript "nvm" ''
  #!/bin/sh
  echo $@
''
