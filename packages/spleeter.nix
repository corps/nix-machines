{ pkgs ? import <nixpkgs> {}
, python3 ? pkgs.python3
, lib ? pkgs.lib
, buildPythonApplication ? python3.pkgs.buildPythonApplication
, fetchPypi ? python3.pkgs.fetchPypi 
, callPackage ? pkgs.callPackage
}:

buildPythonApplication rec {
  pname = "spleeter";
  version = "2.3.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "qHGh17epFcusNNXMY9YKHUXQbR/NB7wZMYyDVW1N6Jc=";
  };

  propagatedBuildInputs = with python3.pkgs; [ 
    ffmpeg-python 
    protobuf 
    (callPackage ./norbert.nix { inherit python3; })
    tensorflow 
    typer 
  ];

  doCheck = false;
}
