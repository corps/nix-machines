{ pkgs, fetchFromGitHub }:

pkgs.python.buildEnv.override {
  extraLibs = let p = pkgs.python35Packages; in [ p.notebook ];
  ignoreCollisions = true;
}
