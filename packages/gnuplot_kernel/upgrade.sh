#! /usr/bin/env nix-shell
#! nix-shell -i bash -p fetch_from_pypi

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

expression=`fetch-from-pypi metakernel wheel`
expression=${expression::-1}
expression=${expression:10}
echo $expression
echo "$expression" > metakernel-package.nix


expression=`fetch-from-github has2k1/gnuplot_kernel`
expression=${expression::-1}
echo $expression
echo "{ fetchFromGitHub }:" > gnuplot-package.nix
echo "$expression" >> gnuplot-package.nix

