{ config, lib, pkgs, ... }:

let 
  ucsfpwPath = /home/home/ucsfwpa.pass;
  ucsfpw = if builtins.pathExists ucsfpwPath then builtins.fromJSON (builtins.readFile ucsfpwPath) else "";
in

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
  ];

  # users
  users.extraUsers.home = {
    isNormalUser = true;
    extraGroups = ["wheel" "networkmanager" "docker"];
    openssh.authorizedKeys.keys = (import ../../authorized-keys.nix).github.corps;
  };

  networking.wireless.userControlled.enable = true;

  # networking
  networking.wireless.networks = {
    projector = {
      psk = "ramenonice";
    };
    UCSFwpa = {
      auth = ''
        key_mgmt=WPA-EAP
        eap=PEAP
        identity="CAMPUS\zcollins1"
        password="${ucsfpw}"
      '';

      priority = 100;
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
    "MyHouse-Guest" = {
      psk = "airbnb3832";
    };
    HHonors = {};
    ihgconnect = {};
  };

  networking.firewall.enable = true;
  networking.firewall.allowedTCPPorts = [ 80 443 ];
  # Port ranges could be specified.

  networking.extraHosts =
    ''
      127.0.0.1 janus.development.local
      127.0.0.1 metis.development.local
      127.0.0.1 timur.development.local
      127.0.0.1 magma.development.local
      127.0.0.1 vulcan.development.local
      127.0.0.1 polyphemus.development.local
      127.0.0.1 prometheus.development.local
      127.0.0.1 grafana.development.local
    '';


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

  boot.kernel.sysctl = { "fs.inotify.max_user_watches" = 65536; };
  
  # Nix
  nix.gc.automatic = true;
  nixpkgs.config.allowUnfree = true;
}

