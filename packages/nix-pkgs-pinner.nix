{ writeScriptBin, bash, git, nix }:

# Do a thing
writeScriptBin "nix-pkgs-pinner" ''
  #! ${bash}/bin/bash

  set -e
  set -o pipefail

  export PATH=${git}/bin:${nix}/bin:$PATH

  branch=''${1:-nixos-unstable}
  out=''${2:-pinned.nix}
  owner=NixOS
  repo=nixpkgs-channels

  rev=`git ls-remote git@github.com:$owner/$repo $branch --refs | head -1 | cut -f 1`
  url=https://github.com/$owner/$repo/archive/$rev.tar.gz
  date=`date`

  release_sha256=$(nix-prefetch-url --unpack "$url")

  cat <<NIXPKGS | tee $out
  # Generated from branch $branch on $date
  builtins.fetchGit {
    name = "nixpkgs-pinned";
    url = "https://github.com/$owner/$repo";
    rev = "$rev";
    ref = "refs/heads/$branch";
  }
  NIXPKGS
''
