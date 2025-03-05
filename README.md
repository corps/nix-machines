# nix-machines

My personal software projects, docker swarm, and nix definitions.  Sort of my evolving mono repo for projects
and configs.

## Setting up a new machine

`./compost/compost.sh` is an idempotent script helper intended to help bootup a new machine for nix
and either home-manager or nix-darwin dependening on the machine. Currently, it assumes NixOS for linux,
and won't install the nix-daemon for non darwin installations.

After initializing nix, `compost.sh` will attempt to run nixos rebuild if applicable, then
home-manager / nix-darwin rebuild, using `./flake.nix` as the entrypoint. Some work is ongoing to
translate existing machines to using the flake. There are often some chicken-egg situations when
getting a machine first configured -- such as getting darwin up to xcode installation completion,
or configuring the hardware part of nixos.

Once you can mostly complete `compose.sh`, you should be able to add entries to `flake.nix` for machine
configuration. Generally, the details of the configuration are split into a top level directory named
after that machine, such as `./excalibur/` or `./saikoro/`.  `/etc/nixos/` related configuration is
left private on the machine in question.

Details of common machine configuration are split into nix modules under `./modules/`. Most of these modules
are intended to be shared between NixOS, home-manager, nix-darwin, and even `mkShell` contexts. There tends
to be an entrypoint module such as `darwin.nix`, `shell.nix`, etc, that handles the full translation between
these contexts.

## Makefiles

Building and deploying docker related parts are managed via `Makefile`s, and a few helpful scripts and tools
are stored in`./maketools/`.
