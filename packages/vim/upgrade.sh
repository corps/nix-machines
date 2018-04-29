#!/usr/bin/env nix-shell
#! nix-shell -i bash -p fetch_from_github git openssl

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" 
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cd $DIR/plugins

function join_by { local IFS="$1"; shift; echo "$*"; }

for file in *.nix
do
  file="${file%.*}"
  IFS="." read -r -a fileParts <<< "$file"
  owner=${fileParts[0]}
  repo=`join_by "." ${fileParts[@]:1}`
  src=`fetch-from-github $owner/$repo`
  file="${file}.nix"
  echo "{ fetchFromGitHub }:" > $file
  echo "${src::-1}" >> $file
done

