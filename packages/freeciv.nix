{ stdenv, coreutils, gcc, unzip, libiconv, 
  gettext, pkgconfig, curlFull, gtk2-x11 }:

stdenv.mkDerivation {
  name = "freeciv";

  buildInputs = [ 
    gcc coreutils unzip libiconv gettext 
    pkgconfig curlFull gtk2-x11 
  ];
  src = ./freeciv-2.5.7.zip;
}
