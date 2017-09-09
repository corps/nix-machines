{ config, lib, pkgs, ... }:
{
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.desktopManager.xfce.enable = true;
  services.xserver.desktopManager.default = "xfce";
  # services.xserver.desktopManager.gnome3.enable = true;
  # services.xserver.desktopManager.default = "gnome3";

  environment.systemPackages = with pkgs; [
    xfce.xfce4mixer
    xfce.xfce4-screenshooter
  ];
}
