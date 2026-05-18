# nix-machines


My personal software projects, docker swarm, and nix definitions.  Sort of my evolving mono repo for projects and configs.

## Setting up a new machine

`./compost/compost.sh` is an idempotent script helper intended to help bootup a new machine for nix
and either home-manager or nix-darwin dependening on the machine.

After initializing nix, `compost.sh` will attempt to run nixos rebuild if applicable, then
home-manager / nix-darwin rebuild, using `./flake.nix` as the entrypoint.  Make sure to configure
either a nixos host or darwin configuration matching the hostname of the machine being setup.

Details of common machine configuration are split into nix modules under `./modules/`. Most of these modules
are intended to be shared between NixOS, home-manager, nix-darwin, and even `mkShell` contexts. There tends
to be an entrypoint module such as `darwin.nix`, `shell.nix`, etc, that handles the full translation between
these contexts.

## Makefiles

Building and deploying docker related parts are managed via `Makefile`s, and a few helpful scripts and tools are stored in`./maketools/`.
