#!/usr/bin/env nix-shell
#! nix-shell -i bash -p fetch_from_github

set -e

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" 
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

fetchSrcCode=`fetch-from-github andreafabrizi/Dropbox-Uploader`

printf "{ fetchFromGitHub }: ${fetchSrcCode::-1}\n" > $DIR/src.nix
