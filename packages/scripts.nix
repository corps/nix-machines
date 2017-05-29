{ stdenv }:
stdenv.mkDerivation {
  name = "corpscripts";
  src = ./scripts;
  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp * $out/bin/
  '';
}
