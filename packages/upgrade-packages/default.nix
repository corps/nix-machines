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

  IFS=", "

  echo $1
  if [[ -z "$1" ]]
  then
    files=**/upgrade.sh
  else
    files=$1*/**/upgrade.sh
  fi

  read -p "Upgrade $files? (Yy/Nn): " -n 1 -r
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

