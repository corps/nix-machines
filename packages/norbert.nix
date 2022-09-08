{ pkgs ? import <nixpkgs> {}
, python3 ? pkgs.python3
, lib ? pkgs.lib
, buildPythonPackage ? python3.pkgs.buildPythonPackage
, fetchPypi ? python3.pkgs.fetchPypi 
}:

buildPythonPackage rec {
  pname = "norbert";
  version = "0.2.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "vUy8JSfwVQuBv0JlwaZLNSyrf3Hk48gj0wtxpzaN504=";
  };

  propagatedBuildInputs = with python3.pkgs; [ scipy ];

  doCheck = false;
}
