{ pkgs ? import <nixpkgs> {}
, stdenv ? pkgs.stdenv
, fetchFromGitHub ? pkgs.fetchFromGitHub
, buildDunePackage ? pkgs.ocamlPackages.buildDunePackage
, uutf ? pkgs.ocamlPackages.uutf
}:
let 

baseAttrs = rec {
  pname = "csv";
  version = "2.4";

  minimumOCamlVersion = "4.03";

  src = fetchFromGitHub {
    owner  = "Chris00";
    repo   = "ocaml-csv";
    rev    = version;
    sha256 = "0y2hlqlmqs7r4y5mfzc5qdv7gdp3wxbwpz458vf7fj4593vg94cf";
  };
};

csv = buildDunePackage baseAttrs // {
  buildInputs = [ ];
  propagatedBuildInputs = [ uutf ];
  doCheck = false;
};

in

buildDunePackage (baseAttrs // {
  pname = "csvtool";
  buildInputs = [ ];
  propagatedBuildInputs = [ csv uutf ];
  doCheck = false;
})
