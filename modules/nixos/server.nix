{ config, lib, pkgs, ... }:
{
  imports = [ ./common.nix ];

  # Packages
  environment.systemPackages = with pkgs; [
  ];

  services.openssh.enable = true;
  networking.firewall.allowedTCPPorts = [ 23 ];

  services.xserver.autorun = false;
  services.xserver.enable = false;

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
  };
}
