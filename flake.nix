{
  description = "system configurations";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    easy-purescript-nix.url = "github:justinwoo/easy-purescript-nix";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, flake-utils, easy-purescript-nix, nix-darwin, poetry2nix, ... }:
    {
        darwinConfigurations = rec {
            "saikoro" = nix-darwin.lib.darwinSystem {
              modules = [ ./saikoro/default.nix ];
              specialArgs = { inherit inputs; };
            };
            RY0KG7652H = nix-darwin.lib.darwinSystem {
                modules = [ ./sentry-laptop/home.nix ];
                specialArgs = { inherit inputs; };
            };
            RY0KG7652H-2 = RY0KG7652H;
        };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        config = (pkgs.lib.evalModules { modules = [
          ./modules/shell.nix
          ./modules/python.nix
          ./modules/purescript.nix
          { 
            _module.args = { inherit pkgs; };
            environment.development.enable = true;
            programs.python.default = pkgs.python311;
          }
        ]; }).config;
      in
      {
        devShells.default = pkgs.mkShell { inherit (config) shellHook buildInputs; name = "nix-machines development shell"; };
     }
  );
}
