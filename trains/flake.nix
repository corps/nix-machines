{
  description = "Trains - A web-based railroad game built with NiceGUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = {
    self,
    nixpkgs,
  }: let
    inherit (nixpkgs) lib;

    # Support common systems
    forAllSystems = lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
  in {
    # Development shell
    devShells = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        default = pkgs.mkShell {
          packages = [
            pkgs.uv
            pkgs.python314
            pkgs.rustc
          ];

          shellHook = ''
            unset PYTHONPATH
            export REPO_ROOT=$(pwd)
            export PATH=$PWD/.venv/bin:$PATH
            uv sync
          '';
        };
      }
    );
  };
}
