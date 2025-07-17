{
  description = "system configurations";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    nixos.url = "github:NixOs/nixpkgs/nixos-24.11";
    easy-purescript-nix.url = "github:justinwoo/easy-purescript-nix";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    nix-github-actions.url = "github:nix-community/nix-github-actions";
    nix-github-actions.inputs.nixpkgs.follows = "nixpkgs";
    pre-commit-hooks.url = "github:cachix/git-hooks.nix";
    pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-24.11";
      inputs.nixpkgs.follows = "nixos";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    vine = {
      url = "github:VineLang/vine";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    py-ivm = {
      url = "github:corps/py-ivm";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos,
      home-manager,
      nix-github-actions,
      # easy-purescript-nix,
      nix-darwin,
      # py-ivm,
      # poetry2nix,
      # nix-ld,
      ...
    }:
    let
      supportedSystems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs supportedSystems;
    in
    {
      darwinConfigurations = {
        "saikoro" = nix-darwin.lib.darwinSystem {
          modules = [ ./saikoro/default.nix ];
          specialArgs = { inherit inputs; };
        };
        "Zachs-MacBook-Pro" = nix-darwin.lib.darwinSystem {
          modules = [ ./candid/default.nix ];
          specialArgs = { inherit inputs; };
        };
      };

      homeConfigurations = {
        "home@excalibur" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixos { system = "x86_64-linux"; };
          modules = [
            ./excalibur/home.nix
          ];
          extraSpecialArgs = { inherit inputs; };
        };
        "home@mikazuki" = home-manager.lib.homeManagerConfiguration {
          pkgs = import nixos { system = "x86_64-linux"; };
          modules = [
            ./mikazuki/home.nix
          ];
          extraSpecialArgs = { inherit inputs; };
        };
      };

      nixosConfigurations = {
        mikazuki = nixos.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (
              if builtins.pathExists /etc/nixos/configuration.nix then
                /etc/nixos/configuration.nix
              else
                # Simple approximation for nix flake check runs
                {
                  networking.hostName = "mikazuki";
                  system.stateVersion = "24.11";
                  fileSystems."/" = {
                    device = "/dev/disk/by-uuid/xxxx";
                    fsType = "ext4";
                  };
                  boot.loader.systemd-boot.enable = true;
                }
            )
            ./mikazuki/host.nix
          ];
        };

        excalibur = nixos.lib.nixosSystem {
          system = "x86_64-linux";
          modules = [
            (
              if builtins.pathExists /etc/nixos/configuration.nix then
                /etc/nixos/configuration.nix
              else
                # Simple approximation for nix flake check runs
                {
                  networking.hostName = "excalibur";
                  system.stateVersion = "20.09";
                  fileSystems."/" = {
                    device = "/dev/disk/by-uuid/xxxx";
                    fsType = "ext4";
                  };
                  boot.loader.systemd-boot.enable = true;
                }
            )
            ./excalibur/host.nix
          ];
        };
      };

      githubActions = nix-github-actions.lib.mkGithubMatrix {
        checks = nixpkgs.lib.getAttrs [ "x86_64-linux" ] self.checks;
      };

      dev = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in

        (pkgs.lib.evalModules {
          modules = [
            ./modules/shell.nix
            ./modules/python.nix
            {
              _module.args = { inherit pkgs inputs; };
              programs.python.default = pkgs.python311;
            }
          ];
        }).config
      );

      checks = forAllSystems (system: self.dev.${system}.checks);

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.dev.${system}) shellHook buildInputs;
          name = "nix-machines development shell";
        };
      });
    };
}
