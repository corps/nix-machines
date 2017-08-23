{ config, pkgs, ... }:

{
  imports =
    [
      ./hardware-configuration.nix
      ./nix-machines/dev-server.nix
    ];

  boot.initrd.luks.devices = [
    {
      name = "root";
      device = "/dev/sda3";
      preLVM = true;
    }
  ];
  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  boot.loader.grub.version = 2;
  boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  boot.loader.grub.device = "/dev/sda"; # or "nodev" for efi only
  system.stateVersion = "17.03";
}
