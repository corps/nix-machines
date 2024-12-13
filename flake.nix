{
  description = "system configurations";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    easy-purescript-nix.url = "github:justinwoo/easy-purescript-nix";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    poetry2nix.url = "github:nix-community/poetry2nix";
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
      in
      {
        devShells.default = 
        let inherit (poetry2nix.lib.mkPoetry2Nix { pkgs = nixpkgs.legacyPackages.${system}; }) mkPoetryEnv; in
        pkgs.mkShell {
          name = "development shell";
          
          buildInputs =  (with pkgs; [
              python311
              python311Packages.black
              python311Packages.isort
              python311Packages.pre-commit-hooks
              python311Packages.pip-tools
              pre-commit
          ]);
          shellHook = ''
            source <(spago --bash-completion-script `which spago`)
            source <(node --completion-bash)
            '';
        };
     }
  );
}
