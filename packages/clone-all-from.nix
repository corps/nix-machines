{ writeScriptBin, bash, curl, git, jq }:
writeScriptBin "clone-all-from" ''
  #!${bash}/bin/bash

  PATH=${curl}/bin:${jq}/bin:$PATH
  for repo in $(curl -s https://api.github.com/users/$1/repos | jq '.[]|.ssh_url' -r); do
    git clone $repo
  done
''
