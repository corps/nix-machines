{
  pkgs ? import <nixpkgs> {},
  fetchFromGitHub ? pkgs.fetchFromGitHub }:


let src = fetchFromGitHub {
  owner = "gibiansky";
  repo = "IHaskell";
  rev = "d35628d10a464ee5d4778b787cd9ab1794fcaee8";
  sha256 = "1z24szyag7xmvn7dvhlf33p4b8x95br5r3yvhfsdlz4nrgxppk91";
};

pinnedNix = fetchFromGitHub {
  owner  = "NixOS";
  repo   = "nixpkgs";
  rev    = "ea1d5e9c7a054eb4ec2660e144133bdbb58a0ae0";
  sha256 = "0x95sqfbgdhmnpx3hfgvy7whjgq0d1zlmi8853jhpl7c26bfw07h";
};

in

import "${src}/release.nix" {
  packages = self: with self; [
    lens
    SHA
    attoparsec
    bytestring
    directory
    filepath
    utf8-string
    byteable
  ];

  pkgs = import pinnedNix {};

  systemPackages = pkgs: with pkgs; [
    coreutils
    findutils
    git
    qpdf
  ];
}
