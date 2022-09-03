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
}:

let
  nvim-customized = wrapNeovim neovim-unwrapped {};
  pyvim = pkgs.python3.withPackages(ps: [ ps.pynvim ]);
  src = import ./src.nix;
in

pkgs.writeShellScriptBin "lvim" ''
export PATH=$PATH:${fzf}/bin:${ripgrep}/bin:${fd}/bin:${nodejs}/bin
# ${nodePackages."neovim"}

if ! test -f $HOME/.local/bin/lvim; then
  ${src}/utils/installer/install.sh -l --no-install-dependencies -y
fi

exec $HOME/.local/bin/lvim $@
''
