{ pkgs, fetchFromGitHub }:

let

# rev = "";
  # rev = "beb1f1ea91ef15d5f1b272108b0cf964e47665f2";
  # rev = "e7a432db1e5a0e221e598b7bdd76262056542441";
  # rev = "4d3c396181739cc4e3b8d3a1e1f678dd4c807ff1";

#  sha256 = "02n73jmc0vbb2dq5af70zxms63jbgbnzc70fmw50mcq07fpwa3p9";
  # sha256 = "0a4fx67b0k4m7xyah8102p2r23aljnxmp8qdwri9hpqrz0f99fbz";
  # sha256 = "181abn04vs31904g7y0lx2f72jw7912c3pjiva29y3n1gf54wj9l";


pythonPkgs = pkgs;

# pythonPkgs = import (fetchFromGitHub {
#  owner = "NixOS";
#  repo = "nixpkgs";
#  inherit rev sha256;
# }) {};

in

pythonPkgs.python.buildEnv.override {
  extraLibs = let p = pythonPkgs.python35Packages; in [ p.notebook ];
  ignoreCollisions = true;
}
