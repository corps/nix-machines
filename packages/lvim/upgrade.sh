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

echo "with (import <nixpkgs> {});" > $DIR/src.nix
fetch-from-github LunarVim/LunarVim >> $DIR/src.nix
sed -i '$ s/.$//' src.nix
