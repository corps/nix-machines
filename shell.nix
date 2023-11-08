{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
    nativeBuildInputs = with pkgs; [ python311 python311Packages.black python311Packages.isort python311Packages.pre-commit-hooks ];
    shellHook = "";
}
