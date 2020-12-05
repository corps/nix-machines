{ pkgs ? import <nixpkgs> {}
, stdenv ? pkgs.stdenv
, dpkg ? pkgs.dpkg
, glibc ? pkgs.glibc
, gcc-unwrapped ? pkgs.gcc-unwrapped
, autoPatchelfHook ? pkgs.autoPatchelfHook
, gtk2-x11 ? pkgs.gtk2-x11
, libsoup ? pkgs.libsoup
, libX11 ? pkgs.xorg.libX11
, libsecret ? pkgs.libsecret
, icu ? pkgs.icu
}:
let
  version = "9.1r9.0";
  src = ./ps-pulse-linux-9.1r9.0-b255-ubuntu-debian-64-bit-installer.deb;
  unpackagedPulseAttrs =  {
    system = "x86_64-linux";
    inherit src version;

    # Required for compilation
    nativeBuildInputs = [
      autoPatchelfHook # Automatically setup the loader, and do the magic
      dpkg
    ];

    # Required at running time
    buildInputs = [
      glibc
      gcc-unwrapped
      gtk2-x11
      libsoup
      libX11
      libsecret
      # icu
    ];

    unpackPhase = "true";
  };

  pulseIcuData = stdenv.mkDerivation (unpackagedPulseAttrs // {
    name = "ps-pulse-icu";
    installPhase = ''
      mkdir -p $out
      dpkg -x $src $out
      cp -R $out/usr/local/pulse/* $out
      cd $out
      rm -rf ./usr/
      tar -xzf pulse.tgz

      mkdir -p lib
      mv libicudata*.so* lib/
      rm lib*.so*
      rm pulse* PulseClient*
      ls -la lib
    '';
  });

  pulseIcuLibs = stdenv.mkDerivation (unpackagedPulseAttrs // {
    name = "ps-pulse-icu";
    buildInputs = unpackagedPulseAttrs.buildInputs ++ [ pulseIcuData ];
    installPhase = ''
      mkdir -p $out
      dpkg -x $src $out
      cp -R $out/usr/local/pulse/* $out
      cd $out
      tar -xzf pulse.tgz
      rm -rf ./usr/local/pulse

      mkdir -p lib
      mv libicu*.so* lib/
      rm lib*.so*
      rm pulse* PulseClient*
      ls -la lib
    '';
  });

  pulseLibs = stdenv.mkDerivation (unpackagedPulseAttrs // {
    name = "ps-pulse-libs";
    buildInputs = unpackagedPulseAttrs.buildInputs ++ [ pulseIcuLibs ];
    installPhase = ''
      mkdir -p $out
      dpkg -x $src $out
      cp -R $out/usr/local/pulse/* $out
      cd $out
      tar -xzf pulse.tgz
      rm -rf ./usr/local/pulse

      mkdir -p lib
      rm libicuuc.so.60.2
      mv libpulseui.so_Ubuntu_16_x86_64 libpulseui.so
      rm libpulseui.so_*
      mv lib*.so* lib/

      rm pulse* PulseClient*
      ls -la lib
    '';
  });


in stdenv.mkDerivation (unpackagedPulseAttrs // {
  name = "ps-pulse";
  nativeBuildInputs = unpackagedPulseAttrs.nativeBuildInputs ++ [ pulseLibs ];

  installPhase = ''
    mkdir -p $out
    dpkg -x $src $out
    cp -R $out/usr/local/pulse/* $out
    cd $out
    tar -xzf pulse.tgz
    rm -rf ./usr/local/pulse

    rm lib*.so*

    mkdir -p bin
    mv pulseutil pulsesvc PulseClient* bin/
  '';

  meta = with stdenv.lib; {
    description = "Ps Pulse";
    maintainers = with stdenv.lib.maintainers; [ ];
    platforms = [ "x86_64-linux" ];
  };
})
