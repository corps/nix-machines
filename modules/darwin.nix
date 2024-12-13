{ config, lib, pkgs, ... }:

with lib;

{
  imports = [ 
    ./python.nix
  ];
}
