{ pkgs, stdenv, fetchFromGitHub, Carbon, Cocoa, ApplicationServices, imagemagick }:

let
  v = "0.2.36";

  src = fetchFromGitHub {
    owner = "koekeishiya";
    repo = "chunkwm";
    rev = "v${v}";
    sha256 = "0xb01m9sl9dpa2r2rprhf3ipyy44xf5wafssr84rq1hdvhkk0yb5";
  };
in
stdenv.mkDerivation rec {
  core = pkgs.callPackage ./core.nix {
    inherit src v Carbon Cocoa;
  };

  border = pkgs.callPackage ./plugin.nix {
    name = "border";
    inherit src v Carbon Cocoa ApplicationServices;
  };

  ffm = pkgs.callPackage ./plugin.nix {
    name = "ffm";
    inherit src v Carbon Cocoa ApplicationServices;
  };

  tiling = pkgs.callPackage ./plugin.nix {
    name = "tiling";
    inherit src v Carbon Cocoa ApplicationServices;
  };

  purify = pkgs.callPackage ./plugin.nix {
    name = "purify";
    inherit src v Carbon Cocoa ApplicationServices;
  };

  bar = pkgs.callPackage ./plugin.nix {
    name = "bar";
    inherit src v Carbon Cocoa ApplicationServices;
  };
}
