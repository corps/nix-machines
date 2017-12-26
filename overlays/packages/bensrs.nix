{ stdenv, nodejs }:

stdenv.mkDerivation {
  name = "bensrs";
  version = "1.0";

  buildInputs = [ nodejs ];

  src = ./.;
  phases = [ "buildPhase" "installPhase" ];

  buildPhase = ''
    export NPM_CONFIG_PREFIX=$PWD
    export HOME=$PWD
    npm install nativefier
    ./node_modules/.bin/nativefier --name "BenSRS" "https://corps.github.io/ben-srs"
  '';

  installPhase = ''
    mkdir -p $out/Applications
    cp -r BenSRS-darwin-x64/BenSRS.app $out/Applications/
  '';
}
