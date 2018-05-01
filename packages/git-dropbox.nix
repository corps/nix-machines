{ writeScriptBin }:

writeScriptBin "git-dropbox" (builtins.readFile ./git-dropbox.sh)
