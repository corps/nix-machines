{ writeText, gitAndTools, bash, substituteAll }:
substituteAll rec {
  src = writeText "fetch-from-github" ''
    #! @bash@/bin/bash

    set -e

    branch=''${2:-master}
    rev=''${3:-$(@git@/bin/git ls-remote https://github.com/$1 $branch --refs | head -1 | cut -f 1)}

    repoName=$1
    IFS='/' read owner repo <<< "$repoName"

    url="https://github.com/$repoName/archive/''${rev}.tar.gz"
    sha256=$(nix-prefetch-url --unpack --type sha256 "$url" --quiet)

    echo "fetchFromGithub {
      owner = \"$owner\";
      repo = \"$repo\";
      rev = \"$rev\";
      sha256 = \"$sha256\";
    };"
  '';

  name = "fetch-from-github";
  isExecutable = true;
  dir = "bin";

  inherit bash;
  git = gitAndTools.git;
}
