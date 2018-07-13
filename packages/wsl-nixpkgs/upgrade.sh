#! /usr/bin/env nix-shell
#! nix-shell -i bash -p gitAndTools.git

set -e
set -o pipefail

SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
  DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"
  SOURCE="$(readlink "$SOURCE")"
  [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE" 
done
DIR="$( cd -P "$( dirname "$SOURCE" )" && pwd )"

cd $DIR

ref=`git ls-remote git@github.com:NixOS/nixpkgs master --refs | head -1 | cut -f 1`

url=https://github.com/NixOS/nixpkgs/archive/$ref.tar.gz
echo "$url" > url
nix-prefetch-url --unpack "$url"
