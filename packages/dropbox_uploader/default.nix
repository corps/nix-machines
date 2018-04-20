{ stdenv, makeWrapper, curl, bash, coreutils, gnused, which, gnugrep, callPackage }:

stdenv.mkDerivation {
  name = "dropbox_uploader";

  buildInputs = [ makeWrapper ];
  src = callPackage ./src.nix {};
  phases = ["unpackPhase" "installPhase"];
  installPhase = ''
    mkdir -p $out/bin
    chmod +x dropbox_uploader.sh
    cp dropbox_uploader.sh $out/bin/dropbox_uploader
    for prg in $out/bin"/"*;do
      wrapProgram $prg --set PATH "${bash}/bin:${curl}/bin:${coreutils}/bin:${gnused}/bin:${which}/bin:${gnugrep}/bin"
    done
  '';
}
