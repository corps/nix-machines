{ pkgs ? import <nixpkgs> {}
, writeScriptBin ? pkgs.writeScriptBin
, stdenv ? pkgs.stdenv
}:

writeScriptBin "ucsf-vpn" ''
#! ${stdenv.shell}
exec sudo openconnect --authgroup="Dual-Factor Pulse Clients" --protocol=nc https://remote.ucsf.edu/openconnect
''
