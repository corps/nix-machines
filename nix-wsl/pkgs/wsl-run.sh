#! @shell@
set -e
set -o pipefail

if ! pidof -x wsl-rund; then
  echo wsl-rund isnt running!
  exit 1
fi

echo \($@\) \& | nc localhost 15150
