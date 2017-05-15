{
    nixpkgs ? <nixpkgs>,
    system ? builtins.currentSystem,
    pkgs ? import nixpkgs { inherit system; }
}:

{
  ngrok = pkgs.callPackage ./ngrok.nix {};
  xquartz-helpers = pkgs.callPackage ./xquartz-helpers.nix {};
}
