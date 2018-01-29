{src, v, stdenv, fetchFromGitHub, Carbon, Cocoa }:

stdenv.mkDerivation rec {
  name = "chunkwm-core-${v}";
  version = "${v}";

  inherit src;

  buildInputs = [ Carbon Cocoa ];

  #HACKY way to get macOS' clang++
  prePatch = ''
    export NIX_LDFLAGS="$NIX_LDFLAGS -F/System/Library/Frameworks"
    substituteInPlace makefile \
      --replace clang++ /usr/bin/clang++
  '';

  buildPhase = ''
    PATH=$PATH:/System/Library/Frameworks make install
    clang $src/src/chunkc/chunkc.c -O2 -o ./bin/chunkc
  '';

  installPhase = ''
    mkdir -p $out/bin
    cp ./bin/* $out/bin/
  '';

  meta = with stdenv.lib; {
    description = "A tiling window manager for macOS";
    homepage = https://github.com/koekeishiya/chunkwm;
    downloadPage = https://github.com/koekeishiya/chunkwm/releases;
    platforms = platforms.darwin;
    maintainers = with maintainers; [ peel ];
    license = licenses.mit;
  };
}
