{ pkgs ? import <nixpkgs> {}
, stdenv ? pkgs.stdenv
, dpkg ? pkgs.dpkg
, buildFHSUserEnv ? pkgs.buildFHSUserEnv
, writeScript ? pkgs.writeScript
, zlib ? pkgs.zlib
, openssl ? pkgs.openssl
, sed ? pkgs.gnused
, autoPatchelfHook ? pkgs.autoPatchelfHook
}:

let 
  pulse-vpn = stdenv.mkDerivation {
    name = "pulse-vpn";
    builder = ./builder.sh;
    dpkg = dpkg;
    buildInputs = [ 
      sed openssl zlib pkgs.webkit 
      pkgs.gnome3.webkitgtk 
      pkgs.libgnome_keyring
    ];
    nativeBuildInputs = [ autoPatchelfHook ];
    src = ./ps-pulse-linux-9.1r4.0-b143-ubuntu-debian-64-bit-installer.deb;
  };
  fhs = buildFHSUserEnv {
    name = "fhs-pulse-vpn";
    targetPkgs = pkgs: [ pulse-vpn ];
    multiPkgs = pkgs: [ pkgs.dpkg pkgs.openssl pkgs.zlib ];
    runScript = "bash";

    extraBuildCommands = ''
      cd $out/usr
      ln -s ${pulse-vpn}/local local
    '';
  };
in
  pulse-vpn


# UBUNTU_16_17_18_DEPENDENCIES=( libc6 \
#                     libwebkitgtk \
#                     libproxy1 \
#                     libproxy1-plugin-gsettings \
#                     libproxy1-plugin-webkit \
#                     libdconf1 \
#                     libgnome-keyring0 \
#                     dconf-gsettings-backend)
