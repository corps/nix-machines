{ config, lib, pkgs, ... }:

{
  nixpkgs.config = (import ../../config.nix { inherit pkgs; });
}
