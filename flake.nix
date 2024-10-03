{
  description = "system configurations";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    easy-purescript-nix.url = "github:justinwoo/easy-purescript-nix";
    nixvim = {
#        url = "github:nix-community/nixvim";
        url = "github:nix-community/nixvim/nixos-24.05";
        inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
  };


  outputs = inputs@{ nixpkgs, flake-utils, easy-purescript-nix, nixvim, nix-darwin, ... }:
    {
        darwinConfigurations = {
            RY0KG7652H = nix-darwin.lib.darwinSystem {
                modules = [ ./sentry-laptop/home.nix ];
                specialArgs = { inherit inputs; };
            };
        };
    } //
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        nixconfig = {
            opts = {
              number = true;         # Show line numbers
              shiftwidth = 2;        # Tab width should be 2
            };

            plugins.lsp.enable = true;
            plugins.barbecue.enable = true;
            plugins.chadtree.enable = true;

            globals.mapleader = "<space>";

            keymaps = [
            ];

            colorschemes.rose-pine.enable = true;

            extraPlugins = with pkgs.vimPlugins; [
              vim-nix
            ];
        };
        nixvim' = nixvim.legacyPackages.${system};
        nvim = nixvim'.makeNixvim nixconfig;
      in
      {
        devShells.default = pkgs.mkShell {
          name = "development shell";
          buildInputs = [
            nvim
          ] ++ (with pkgs; [
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
