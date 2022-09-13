{ config, lib, pkgs, ... }:

{
  # security.enableAccessibilityAccess = true;
  services.khd.enable = true;

  environment.systemPackages = with pkgs; [ khd ];

  services.khd.khdConfig = ''
    shift + cmd - d : open -a "Firefox"
    shift + cmd - e : open -a "alacritty"
  '';
}
