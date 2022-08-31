{ config, lib, pkgs, ... }:
{
  imports = [ ./common.nix ];

  # Packages
  environment.systemPackages = with pkgs; [
    neovim
  ];

  services.openssh.enable = true;
  # ssh
  networking.firewall.allowedTCPPorts = [ 22 ];

  services.xserver.autorun = false;
  services.xserver.enable = false;

  system.autoUpgrade = {
    enable = true;
    allowReboot = true;
  };
}
