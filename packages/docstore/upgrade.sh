#! /usr/bin/env nix-shell
#! nix-shell -i bash -p fetch_from_github

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

expression=`fetch-from-github corps/docstore`
expression=${expression::-1}
echo $expression
echo "{ fetchFromGitHub }:" > package.nix
echo "$expression" >> package.nix

