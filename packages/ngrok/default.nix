{ system, stdenv, unzip, wget, substituteAll, bash }:

let
  ngrokUrl = {
    "x86_64-linux" = "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-linux-amd64.zip";
    "x86_64-darwin" = "https://bin.equinox.io/c/4VmDzA7iaHb/ngrok-stable-darwin-amd64.zip";
  }."${system}";
in

stdenv.mkDerivation {
  name = "ngrok";

  ngrok = substituteAll {
    src = ./ngrok.sh;
    name = "ngrok.sh";
    isExecutable = true;
    inherit unzip wget bash ngrokUrl;
  };

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp $ngrok $out/bin/ngrok
  '';
}