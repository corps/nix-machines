{ writeScriptBin, bash }:

let
packagesSrcRoot = toString ./..;
in

writeScriptBin "upgrade-packages" ''
  #! ${bash}/bin/bash
  set -e
  set -o pipefail

  export PATH=${bash}/bin/bash:$PATH

  cd ${packagesSrcRoot}

  shopt -s nullglob
  shopt -s globstar

  if [[ -z "$1" ]]
  then
    files=*/upgrade.sh
  else
    files=$1*/upgrade.sh
  fi

  echo Found $files
  read -p "Upgrade? (Yy/Nn): " -n 1 -r
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    for file in $files
    do
      set -x
      $file
      set +x
    done

    git diff
  fi
''

