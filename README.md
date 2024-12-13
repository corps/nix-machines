# nix-machines

My personal software projects, docker swarm, and nix definitions.

## Setting up a new machine

Use one of the entrypoints in the ./compost directory, such as darwin-compost.sh
Several attempts may be necessary as side effects are required outside of the compost environment,
such as creating a machine definition in flake.nix, or installing xCode, etc.  The entrypoints are
idempotent, however, so run as necessary to complete setup.

Machines are configured now through flake.nix, but some historical setups require linking a nix home
configuration file into the right place. Goal is to move more towards flakes in general.

## Using the directory

Make sure the `direnv` and `nix-direnv` are installed, then `direnv allow` this top level directory.
