# nix-machines

My personal software projects, docker swarm, and nix definitions.

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
after that machine, such as `./excalibur/` or `./saikoro/`.

Details of common machine configuration are split into nix modules under `./modules/`. Most of these modules
are intended to be shared between NixOS, home-manager, nix-darwin, and even `mkShell` contexts. There tends
to be an entrypoint module such as `darwin.nix`, `shell.nix`, etc, that handles the full translation between
these contexts. Don't forget to write your modules with the shared contexts in mind, using options or conditionals
to enable or disable parts of configuration that make more or less sense depending on the deployment context.

## Updating flakes

Since I use `nix flakes`, versions of all inputs are pinned via `flake.lock`. Use `nix` commands to bump this and
check in working configurations. Sometimes this can and will cause issues in other environments when upgrades
break things. It is possible to use different nixpkg versions in flake inputs if it becomes necessary.

TODO: Setup ci to atleast check / build configurations before allowing merge.

Honestly, I don't mind some failure modes for the flexibility of quick development. This repo is always a WIP
and tightly coupled to my workflows.

## Makefiles

Software projects that I intend to deploy are organized via `Makefile`s in top level and nested directories.
The default `make` target provides a helpful list of available commands in any context. Shared targets
and build utilities are organized in `./maketools/`.

Notably, tools for building a `Dockerfile` and its implicit dependencies are included, as well as tools
for configuring and deploying those to dockerswarm environments. Refer to documentation in the relevant
directory.
