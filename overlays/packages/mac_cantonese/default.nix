{ stdenv }:

stdenv.mkDerivation {
  name = "mac_cantonese-input-plugin";
  version = "1.1";
  phases = [ "unpackPhase" "installPhase" ];

  src = ./.;

  installPhase = ''
    mkdir -p $out
    cp ./canto.cin $out/canto.cin
  '';
}
