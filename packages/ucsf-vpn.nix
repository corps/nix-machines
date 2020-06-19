{ pkgs ? import <nixpkgs> {}
, writeScriptBin ? pkgs.writeScriptBin
, stdenv ? pkgs.stdenv
}:

writeScriptBin "ucsf-vpn" ''
#! ${stdenv.shell}
exec sudo openconnect --authgroup="Dual-Factor Pulse Clients" --juniper https://remote.ucsf.edu/openconnect
''
