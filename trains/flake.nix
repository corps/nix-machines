{
  description = "Trains - A web-based railroad game built with NiceGUI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      uv2nix,
      pyproject-nix,
      pyproject-build-systems,
    }:
    let
      inherit (nixpkgs) lib;

      # Support common systems
      forAllSystems = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

    in
    {
      # Package outputs
      packages = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Load the workspace from uv.lock
          workspace = uv2nix.lib.workspace.loadWorkspace {
            workspaceRoot = ./.;
          };

          # Create an overlay with all Python packages
          overlay = workspace.mkPyprojectOverlay {
            sourcePreference = "wheel";
          };

          # Extend Python package set with our overlay
          pythonSet = pkgs.callPackage pyproject-nix.build.packages {
            python = pkgs.python314;
          };

          pythonSetWithOverlay = pythonSet.overrideScope (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.default
              overlay
            ]
          );

          # Create production virtualenv with trains package
          virtualenv = pythonSetWithOverlay.mkVirtualEnv "trains-env" workspace.deps.default;

          # Helper to create wrapper scripts
          makeWrapper =
            name: script:
            pkgs.writeShellScriptBin name ''
              exec ${virtualenv}/bin/${script} "$@"
            '';

        in
        {
          default = virtualenv;
          trains-server = makeWrapper "trains-server" "trains-server";
          trains-map-viewer = makeWrapper "trains-map-viewer" "trains-map-viewer";
        }
      );

      # Development shell
      devShells = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          default = pkgs.mkShell {
            packages = [
              pkgs.uv
              pkgs.python314
            ];

            shellHook = ''
              unset PYTHONPATH
              export REPO_ROOT=$(pwd)
              export PATH=$PWD/.venv/bin:$PATH
              uv sync

              echo "🚂 Trains development environment"
              echo ""
              echo "Available commands:"
              echo "  trains-server      - Run the trains server"
              echo "  trains-map-viewer  - Run the map viewer"
              echo "  uv sync           - Sync dependencies"
              echo "  pytest            - Run tests"
              echo ""
            '';
          };
        }
      );
    };
}
