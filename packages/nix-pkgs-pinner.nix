{ writeScriptBin, bash, curl, jq, nix }:

writeScriptBin "nix-pkgs-pinner" ''
  #! ${bash}/bin/bash

  export PATH=${curl}/bin:${jq}/bin:${nix}/bin:$PATH

  set -eufo pipefail

  FILE=$1
  PROJECT=$2
  BRANCH=''${3:-master}

  OWNER=$(jq -r '.[$project].owner' --arg project "$PROJECT" < "$FILE")
  REPO=$(jq -r '.[$project].repo' --arg project "$PROJECT" < "$FILE")

  REV=$(curl "https://api.github.com/repos/$OWNER/$REPO/branches/$BRANCH" | jq -r '.commit.sha')
  SHA256=$(nix-prefetch-url --unpack "https://github.com/$OWNER/$REPO/archive/$REV.tar.gz")
  TJQ=$(jq '.[$project] = {owner: $owner, repo: $repo, rev: $rev, sha256: $sha256}' \
    --arg project "$PROJECT" \
    --arg owner "$OWNER" \
    --arg repo "$REPO" \
    --arg rev "$REV" \
    --arg sha256 "$SHA256" \
    < "$FILE")
  [[ $? == 0 ]] && echo "''${TJQ}" >| "$FILE"
''
