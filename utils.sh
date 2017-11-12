IFS=$'\n'
RED='\033[00;31m'
GREEN='\033[00;32m'
YELLOW='\033[00;33m'
BLUE='\033[00;34m'
PURPLE='\033[00;35m'
CYAN='\033[00;36m'
RESTORE='\033[0m'

function check() {
  echo -en "checking $CYAN"
  echo -en " $@"
  echo -en "$RESTORE "
  if ($@ &> /dev/null)
  then
    echo -en $GREEN
    echo -e yes
    echo -en $RESTORE
    return 0;
  else
    echo -en $YELLOW
    echo -e no
    echo -en $RESTORE
    return 1;
  fi
}

function directoryEmpty() {
  [[ -z "$(ls -A $1)" ]]
}

function runningOnPort() {
  (nc -z localhost "$1" &> /dev/null)
}

function listContains() {
  eval $1 | grep -F "$2"
}

function isDarwin() {
  [[ $(uname -s) =~ "Darwin" ]]
}

function fileExists() {
  [ -e "$1" ]
}

function versionMatches() {
  local versionOut=$($1 --version)
  [[ $versionOut =~ "$2" ]]
}

function versionAtleast() {
  local IFS='.'
  local expected got

  version=$($1 --version)
  [[ "$version" =~ ([0-9]+\.?([0-9]+\.?)*) ]] && version="$BASH_REMATCH"

  read -a expected <<< "$2"
  read -a got <<< "$version"

  while [[ -n "$expected" || -n "$got" ]]; do
    [[ ! -n "$got" ]] && return 1;
    [[ ! -n "$expected" ]] && return 0;
    [[ "$expected" -gt "$got" ]] && return 1;
    [[ "$expected" -lt "$got" ]] && return 0;

    got=("${got[@]:1}")
    expected=("${expected[@]:1}")
  done
}

function await() {
  while ! check $@; do
    sleep 1
  done
}

function fileExists() {
  [[ -e "$1" ]]
}

function echoRun() {
  echo -e "running $CYAN "$@" $RESTORE"
  $@
}

function hardRemove() {
  if fileExists "$1"; then
    echoRun sudo rm -rf $1
  fi
}

function confirm() {
  read -p "$1 (Yy/Nn): " -n 1 -r
  echo
  [[ $REPLY =~ ^[Yy]$ ]]
}

function isNonRootUser() {
  [[ $EUID -ne 0 ]];
}

function isXcodeInstalled() {
  local result
  set +e
  xcode-select -p &> /dev/null
  result=$?
  set -e
  [ $result -eq 0 ]
}

function existsOnPath() {
  local result
  set +e
  which "$1" > /dev/null
  result=$?
  set -e
  [ $result -eq 0 ]
}

function isLink() {
  [ -L "$1" ]
}

function exitWithMessage() {
  echo "$2"
  exit $1
}