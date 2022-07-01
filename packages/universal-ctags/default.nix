{ stdenv, fetchFromGitHub, autoreconfHook, pkgconfig, perl, pythonPackages, libiconv, callPackage, lib }:

stdenv.mkDerivation rec {
  name = "universal-ctags";

  src = callPackage ./package.nix {};

  nativeBuildInputs = [ pythonPackages.docutils ];
  buildInputs = [ autoreconfHook pkgconfig libiconv ];

  autoreconfPhase = ''
    ./autogen.sh --tmpdir
  '';

  postConfigure = ''
    sed -i 's|/usr/bin/env perl|${perl}/bin/perl|' misc/optlib2c
  '';

  doCheck = false;

  checkFlags = "units";

  meta = with lib; {
    description = "A maintained ctags implementation";
    homepage = https://ctags.io/;
    license = licenses.gpl2Plus;
    platforms = platforms.unix;
    # universal-ctags is preferred over emacs's ctags
    priority = 1;
    maintainers = [ maintainers.mimadrid ];
  };
}
