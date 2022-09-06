{ pkgs ? import <nixpkgs> {}
, neovim-unwrapped ? pkgs.neovim-unwrapped
, wrapNeovim ? pkgs.wrapNeovim
, fetchFromGitHub ? pkgs.fetchFromGitHub
, stdenv ? pkgs.stdenv
, makeWrapper ? pkgs.makeWrapper
, lib ? pkgs.lib
, ripgrep ? pkgs.ripgrep
, fzf ? pkgs.fzf
, fd ? pkgs.fd
, bash ? pkgs.bash
, python3 ? pkgs.python3
, nodePackages ? pkgs.nodePackages
, nodejs ? pkgs.nodejs
, srcRoot ? toString ./.
}:

let
  nvim-customized = wrapNeovim neovim-unwrapped {};
  pyvim = pkgs.python3.withPackages(ps: [ ps.pynvim ]);
  src = import ./src.nix;
in

pkgs.writeShellScriptBin "lvim" ''
set -e
docker build ${srcRoot} --tag lvim

runOpts="--rm -it --user $(id -u):$(id -g)"

if test -f "$1"; then
  exec docker run $runOpts -v "$(dirname $1)":/workdir lvim vim "/workdir/$(basename $1)"
elif test -d "$1"; then
  exec docker run $runOpts -v "$1":/workdir lvim vim /workdir
else
  exec docker run $runOpts -v $HOME:/workdir lvim vim /workdir
fi
''
