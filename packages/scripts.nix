{ stdenv }:
stdenv.mkDerivation {
  name = "corpscripts";
  src = ./scripts;
  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    cp * $out/bin/
  '';
}
