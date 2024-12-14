{
  description = "system configurations";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nixos.url = "github:NixOs/nixpkgs/nixos-24.11";
    flake-utils.url = "github:numtide/flake-utils";
    easy-purescript-nix.url = "github:justinwoo/easy-purescript-nix";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
        home-manager = {
            url = "github:nix-community/home-manager/release-24.11";
            # url = "github:nix-community/home-manager";
            # url = "github:nix-community/home-manager/release-24.05";
            inputs.nixpkgs.follows = "nixos";
        };
  };

  outputs = inputs@{ nixpkgs, nixos, flake-utils, home-manager, easy-purescript-nix, nix-darwin, poetry2nix, ... }:
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

        homeConfigurations.home = home-manager.lib.homeManagerConfiguration {
            pkgs = import nixos { system = "x86_64-linux"; };
            modules = [ 
              ./excalibur/home.nix 
            ];
            extraSpecialArgs = { inherit inputs; };
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
            _module.args = { inherit pkgs inputs; };
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
