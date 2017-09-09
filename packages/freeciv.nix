{ stdenv, coreutils, gcc, unzip, libiconv, fetchurl,
  gettext, pkgconfig, curlFull, gtk2-x11 }:

stdenv.mkDerivation {
  name = "freeciv";

  buildInputs = [
    gcc coreutils unzip libiconv gettext
    pkgconfig curlFull gtk2-x11
  ];

  src = fetchurl {
    url = "http://files.freeciv.org/stable/freeciv-2.5.9.zip";
    sha256 = "1hzgsq3zgxp8qy37i5jpg6n3b9ki0qc556pqqga0ggdxdn2cy5s8";
  };
}
