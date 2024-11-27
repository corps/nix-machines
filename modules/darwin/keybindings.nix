{ config, lib, pkgs, ... }:

{
  # security.enableAccessibilityAccess = true;
  services.skhd.enable = true;
  # environment.systemPackages = with pkgs; [ khd ];
}
