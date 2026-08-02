{
  description = "system configurations";
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/master";
    nixos.url = "github:NixOs/nixpkgs/nixos-25.05";
    nvf.url = "github:notashelf/nvf";
    nix-darwin.url = "github:LnL7/nix-darwin";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixos";
    };
    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    mistral-vibe = {
      url = "github:mistralai/mistral-vibe";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos,
      home-manager,
      nix-darwin,
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
        "ZacharynoiMac" = nix-darwin.lib.darwinSystem {
          modules = [ ./imac/default.nix ];
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

      dev = forAllSystems (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in

        (pkgs.lib.evalModules {
          modules = [
            ./modules/shell.nix
            {
              _module.args = { inherit pkgs inputs; };
              environment.systemPackages = [ ];
            }
          ];
        }).config
      );

      devShells = forAllSystems (system: {
        default = nixpkgs.legacyPackages.${system}.mkShell {
          inherit (self.dev.${system}) shellHook buildInputs;
          name = "nix-machines development shell";
        };
      });
    };
}
