{ pkgs ? import <nixpkgs> {}
, system  ? pkgs.system
, stdenv ? pkgs.stdenv
, unzip ? pkgs.unzip
, wget ? pkgs.wget
, substituteAll ? pkgs.substituteAll
, bash ? pkgs.bash
, gnutar  ? pkgs.gnutar
}:

let
  ngrokUrl = {
    "x86_64-linux" = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-amd64.tgz";
    "aarch64-linux" = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-linux-arm64.tgz";
    "x86_64-darwin" = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-amd64.tgz";
    "aarch64-darwin" = "https://bin.equinox.io/c/bNyj1mQVY4c/ngrok-v3-stable-darwin-arm64.tgz";
  }."${system}";
in

stdenv.mkDerivation {
  name = "ngrok";

  ngrok = substituteAll {
    src = ./ngrok.sh;
    name = "ngrok.sh";
    isExecutable = true;
    inherit unzip wget bash ngrokUrl gnutar;
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp $ngrok $out/bin/ngrok
  '';
}
