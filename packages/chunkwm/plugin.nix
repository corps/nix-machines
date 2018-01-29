{ name, src, v, stdenv, fetchFromGitHub, Carbon, Cocoa, ApplicationServices, imagemagick ? null}:

stdenv.mkDerivation {
  name = "${name}-${v}";
  version = v;

  inherit src;

  buildInputs = [ Carbon Cocoa ApplicationServices ] ++ [ imagemagick ];

  buildPhase = ''
    export NIX_LDFLAGS="$NIX_LDFLAGS -F/System/Library/Frameworks"
    substituteInPlace src/plugins/${name}/makefile --replace "clang++" "/usr/bin/clang++"
  '';

  installPhase = ''
    cd src/plugins/${name} && make all
    mkdir -p $out/lib/chunkwm/plugins
    cp ../../../plugins/${name}.so $out/lib/chunkwm/plugins/
  '';

  meta = with stdenv.lib; {
    description = "A ChunkWM plugin for ${name}";
    homepage = "https://github.com/koekeishiya/chunkwm";
    downloadPage = "https://github.com/koekeishiya}/chunkwm/releases";
    platforms = platforms.darwin;
    maintainers = with maintainers; [ peel ];
    license = licenses.mit;
  };
}
