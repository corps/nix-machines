{ config, pkgs, ... }:

{
  hardware.pulseaudio.enable = true;

  environment.variables = {
    EDITOR = "nvim";
  };

  environment.systemPackages = with pkgs; [
    neovim 
    xorg.xmodmap
    mkcert
    p11-kit
    davfs2
  ];

  time.timeZone = "America/Los_Angeles";

  # Enable the X11 windowing system.
  services.xserver.enable = true;
  services.xserver.layout = "us";
  services.xserver.xkbOptions = "eurosign:e";

  # Enable touchpad support.
  services.xserver.libinput.enable = true;
  services.xserver.libinput.naturalScrolling = true;
  services.xserver.libinput.dev = null;

  # Enable the KDE Desktop Environment.
  services.xserver.displayManager.sddm.enable = true;
  services.xserver.desktopManager.plasma5.enable = true;

  users.users.home = {
    isNormalUser = true;
    extraGroups = [ "wheel" "networkmanager" "docker" ];
  };

  networking.interfaces.wlp2s0.useDHCP = true;
  # networking.interfaces.wlp2s0.ip4 = [ { address = (import ./port.nix); prefixLength = 24; } ];
  networking.wireless.enable = true;
  networking.wireless.networks = {
    grillspace2 = {
      psk = "stopcownight";
    };
    ORBI46 = {
      psk = "braveflute410";
    };
    fire = {
      psk = "montana93";
    };
    ihgconnect = {};
  };

  virtualisation.docker.enable = true;

  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.addNetworkInterface = true;
  virtualisation.virtualbox.guest.enable = true;

  networking.extraHosts =
    ''
      127.0.0.1 janus.development.local
      127.0.0.1 metis.development.local
    '';


    security.pki.certificateFiles = (if builtins.pathExists "/home/home/.local/share/mkcert/rootCA.pem" then [
      /home/home/.local/share/mkcert/rootCA.pem
    ] else []);
}
