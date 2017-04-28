{
    nixpkgs ? <nixpkgs>,
    system ? builtins.currentSystem,
    pkgs ? import nixpkgs { inherit system; }
}:

{
  ngrok = pkgs.callPackage ./ngrok.nix {};
}