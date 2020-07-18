{ config, pkgs, ... }:

{
  environment.variables = {
    EDITOR = "nvim";
  };

  environment.systemPackages = with pkgs; [
    neovim 
    mkcert
    p11-kit
    davfs2
    dpkg
    binutils
    patchelf
    openconnect
  ];

  time.timeZone = "America/Los_Angeles";

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.home = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ]; # Enable ‘sudo’ for the user.
    openssh.authorizedKeys.keys = (import ../authorized-keys.nix).github.corps;
  };

  virtualisation.docker.enable = true;

  networking.hostName = "comboslice";
  networking.extraHosts =
    ''
    '';
}
