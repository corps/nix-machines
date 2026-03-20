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

  outputs = { self, nixpkgs, uv2nix, pyproject-nix, pyproject-build-systems }:
    let
      inherit (nixpkgs) lib;

      # Support common systems
      forAllSystems = lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];

    in {
      # Package outputs
      packages = forAllSystems (system:
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
            python = pkgs.python312;
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
          makeWrapper = name: script: pkgs.writeShellScriptBin name ''
            exec ${virtualenv}/bin/${script} "$@"
          '';

        in {
          default = virtualenv;

          trains-server = makeWrapper "trains-server" "trains-server";
          trains-map-viewer = makeWrapper "trains-map-viewer" "trains-map-viewer";
        });

      # Development shell
      devShells = forAllSystems (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          # Load workspace for dev shell
          workspace = uv2nix.lib.workspace.loadWorkspace {
            workspaceRoot = ./.;
          };

          # Create overlay for editable install
          editableOverlay = workspace.mkEditablePyprojectOverlay {
            root = "$REPO_ROOT";
          };

          # Create base overlay
          baseOverlay = workspace.mkPyprojectOverlay {
            sourcePreference = "wheel";
          };

          # Python package set with overlays
          pythonSet = pkgs.callPackage pyproject-nix.build.packages {
            python = pkgs.python312;
          };

          pythonSetWithOverlay = pythonSet.overrideScope (
            lib.composeManyExtensions [
              pyproject-build-systems.overlays.default
              baseOverlay
              editableOverlay
            ]
          );

          # Create virtualenv with dev dependencies
          virtualenv = pythonSetWithOverlay.mkVirtualEnv "trains-dev-env" workspace.deps.all;

        in {
          default = pkgs.mkShell {
            packages = [
              virtualenv
              pkgs.uv
            ];

            shellHook = ''
              # Unset PYTHONPATH to avoid conflicts
              unset PYTHONPATH

              # Set repository root for editable install
              export REPO_ROOT=$(pwd)

              # Configure uv to use nix-provided Python
              export UV_PYTHON=${pkgs.python312}/bin/python

              echo "🚂 Trains development environment"
              echo ""
              echo "Available commands:"
              echo "  trains-server      - Run the trains server"
              echo "  trains-map-viewer  - Run the map viewer"
              echo "  uv sync           - Sync dependencies"
              echo "  pytest            - Run tests"
              echo "  mypy              - Type check"
              echo ""
            '';
          };
        });
    };
}
