{ config, lib, pkgs, ... }:

{
  # security.enableAccessibilityAccess = true;
  services.khd.enable = true;

  environment.systemPackages = with pkgs; [ khd ];

  services.khd.khdConfig = ''
    shift + cmd - d : open -a "Brave Browser"
    shift + cmd - e : open -a iTerm
    shift + cmd - 0x27 : open -a BenSRS
    shift + cmd - h : open -a Stickies
  '';
}
