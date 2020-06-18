{ pkgs ? import <nixpkgs> {}
, writeScriptBin ? pkgs.writeScriptBin
, stdenv ? pkgs.stdenv
}:

writeScriptBin "ucsf-vpn" ''
#! ${stdenv.shell}
exec sudo openconnect --authgroup="Dual-Factor Pulse Clients" --juniper https://remote.ucsf.edu/openconnect --servercert sha256:585099c60198e420c12c85218efbd334eb6edf9ebb831d509a04d47accaca684
''
