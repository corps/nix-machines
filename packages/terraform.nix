{ pkgs ? import <nixpkgs> {}
, terraform_0_13 ? pkgs.terraform_0_13
, terraform_0_14 ? pkgs.terraform_0_14
, terraform_0_15 ? pkgs.terraform_0_15
, terraform ? pkgs.terraform
, writeScriptBin ? pkgs.writeScriptBin
, bash ? pkgs.bash
}:

writeScriptBin "terraform" ''
#! ${bash}/bin/bash

DIR=$PWD
ver=
while [[ "$DIR" != / ]]; do
  if [ -e "$DIR/terraform/terraform-version" ]; then
    ver="$(cat "$DIR/terraform/terraform-version")"
    break
  fi
  DIR="$(dirname "$DIR")"
done

if [[ "$ver" =~ 0\.13.* ]]; then
  exec ${terraform_0_13}/bin/terraform $@
elif [[ "$ver" =~ 0\.14.* ]]; then
  exec ${terraform_0_14}/bin/terraform $@
elif [[ "$ver" =~ 0\.15.* ]]; then
  exec ${terraform_0_15}/bin/terraform $@
else
  echo "Could not determine terraform version to use, found '$ver'"
  exit 1
fi
''
