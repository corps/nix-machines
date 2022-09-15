{ config, lib, pkgs, ... }:

{
  # security.enableAccessibilityAccess = true;
  services.khd.enable = true;
  environment.systemPackages = with pkgs; [ khd ];
}
