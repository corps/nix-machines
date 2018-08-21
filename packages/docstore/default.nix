{ callPackage, stdenv, nix }:

let
  inner = import (callPackage ./package.nix {}) {};
in

stdenv.mkDerivation {
  name = "docstore";

  phases = [ "installPhase" ];

  inherit inner;

  installPhase = ''
    mkdir $out
    cp --preserve=links -r $inner/* $out/
  '';
}
