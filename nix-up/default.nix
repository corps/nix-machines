{
  nixpkgs ? <nixpkgs>,
  configuration ? <up-config>,
  system ? builtins.currentSystem,
  pkgs ? import nixpkgs { inherit system; }
}:

let

packages = { config, lib, pkgs, ... }: {
  _file = ./default.nix;
  config = {
    _module.args.pkgs = import nixpkgs config.nixpkgs;
    nixpkgs.system = system;
  };
};

eval = pkgs.lib.evalModules {
  specialArgs = { modulesPath = ./modules; };
  check = true;
  modules = [
    configuration
    packages
    ./modules/system
    ./modules/environment
    ./modules/nix
    ./modules/programs
  ];
};

in

{
  inherit (eval.config._module.args) pkgs;
  inherit (eval) options config;

  system = eval.config.system.build.toplevel;
  installer = pkgs.callPackage ./pkgs/up-installer {};
}
