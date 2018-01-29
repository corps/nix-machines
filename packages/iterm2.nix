{  stdenv, unzip, fetchurl }:

stdenv.mkDerivation {
  name = "iterm2";
  src = fetchurl {
    url = "https://iterm2.com/downloads/stable/iTerm2-3_1_5.zip";
    sha256 = "0sfpkzw71z8y6qz0dyjvzymskr6gz92rlskd79jn2p7yjrncwnbi";
  };

  buildInputs = [ unzip ];

  phases = [ "unpackPhase" "installPhase" ];

  installPhase = ''
    mkdir -p $out/Applications/iTerm.app
    cp -r * $out/Applications/iTerm.app/
  '';
}
