# nix-machines
My personal software projects, docker swarm, and nix definitions.

## Setting up a new machine

* Create a directory containing a `home.nix` and a `server.nix`.
* Import the proper modules from `modules`.
* **For darwin**, add an imports = [ ../machine-config.nix ]; to your ~/.nixpkgs/darwin-configuration.nix file.
  **For nixos**, add NIX_HOME=path-to-home.nix to the environment.
* Run the appropriate compost script in the `compost` dir.

## Using the directory

Make sure the `direnv` and `nix-direnv` are installed, then `direnv allow` this top level directory.

`shell.nix` contains useful programs for development.
