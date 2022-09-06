{ config, lib, pkgs, ... }:

{
  imports = [
    ./docker-services.nix
  ];

  # Environment
  environment.variables = {
    EDITOR = "nvim";
  };
  
  # Packages
  environment.systemPackages = with pkgs; [
    wget 
    git bash
    neovim 
    mkcert
    p11-kit
    davfs2
    dpkg
    binutils
    patchelf
    ngrok
    ripgrep
    nnn
    nodejs
  ];

  # users
  users.extraUsers.home = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "docker"];
    openssh.authorizedKeys.keys = (import ../../authorized-keys.nix).github.corps;
  };

  networking.wireless.userControlled.enable = true;
  # networking.

  # networking
  networking.wireless.networks = {
    projector = {
      psk = "ramenonice";
    };
    UCSFguest = {};
    grillspace2 = {
      psk = "stopcownight";
    };
    magichands = {
      psk = "libbysibby";
    };
    ORBI46 = {
      psk = "braveflute410";
    };
    fire = {
      psk = "montana93";
    };
    ssgooz = {
      psk = "mebejefe";
    };
    "Brutal Poodle" = {
      psk = "Awesome1111!";
    };
    "Hilton Honors" = {};
    HHonors = {};
    ihgconnect = {};
  };

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  # Port ranges could be specified.

  # networking.extraHosts = "";
  networking.nameservers = [ "10.0.0.14" "1.1.1.1" "8.8.8.8" "8.8.4.4" ];

  # Security
  security.sudo.extraRules = [
    { groups = [ "wheel" ];
      commands = [ { command = "/run/current-system/sw/bin/systemctl"; options = [ "SETENV" "NOPASSWD" ]; } ]; }
  ];

  security.pki.certificateFiles = (if builtins.pathExists "/home/home/.local/share/mkcert/rootCA.pem" then [
    /home/home/.local/share/mkcert/rootCA.pem
  ] else []);

  # Virtualization
  virtualisation.docker.enable = true;
  virtualisation.docker.liveRestore = false;
  virtualisation.docker.autoPrune = {
    enable = true;
    dates = "daily";
  };

  time.timeZone = "America/Los_Angeles";

  boot.kernel.sysctl."fs.inotify.max_user_instances" = 2147483647;
  # boot.kernel.sysctl = { "fs.inotify.max_user_watches" = 65536; };
  
  # Nix
  nix.gc.automatic = true;
  nixpkgs.config.allowUnfree = true;
}

