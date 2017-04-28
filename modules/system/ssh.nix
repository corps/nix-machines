{ config, lib, pkgs, ... }:
{
  security.sudo.wheelNeedsPassword = false;

  services.openssh.enable = true;
  services.openssh.forwardX11 = true;
  services.openssh.allowSFTP = true;

  users.extraUsers.root.openssh.authorizedKeys.keys = (import ../../authorized-keys.nix).github.corps;
}
