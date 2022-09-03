{ config, lib, pkgs, ... }:
{
  imports = [ ./common.nix ];

  # Packages
  environment.systemPackages = with pkgs; [
    xorg.xmodmap
    xorg.xrandr
  ];

  # Video
  hardware.opengl.enable = true;

  # X
  services.xserver.enable = true;
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;
  services.xserver.layout = "us";

  services.xserver.libinput.enable = true;
  services.xserver.libinput.naturalScrolling = true;
  # services.xserver.libinput.dev = null;

  # Input
  i18n.inputMethod = {
    enabled = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-mozc ];
  };

  # sound
  sound.enable = true;
  hardware.pulseaudio.enable = true;
}

