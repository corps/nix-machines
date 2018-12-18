#! /usr/bin/env bash

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

channel="$1"

ref=`git ls-remote git@github.com:NixOS/nixpkgs-channels "$channel" --refs | head -1 | cut -f 1`
url=https://github.com/NixOS/nixpkgs-channels/archive/$ref.tar.gz

wget "$url"
tar -xzf $ref.tar.gz

rm $ref.tar.gz
rm -rf $DIR/$channel || true

cd $DIR
ln -s ./nixpkgs-channels-$ref $channel
