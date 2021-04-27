{ config, pkgs, ... }:

{
  hardware.pulseaudio.enable = true;

  environment.variables = {
    EDITOR = "nvim";
  };

  environment.systemPackages = with pkgs; [
    neovim 
    xorg.xmodmap
    xorg.xrandr
    mkcert
    p11-kit
    davfs2
    dpkg
    binutils
    patchelf
    openconnect
  ];

  i18n.inputMethod = {
    enabled = "fcitx";
    fcitx.engines = with pkgs.fcitx-engines; [ mozc ];
  };

  time.timeZone = "America/Los_Angeles";

  hardware.opengl.enable = true;

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
  networking.wireless.enable = true;
  networking.wireless.networks = {
    projector = {
      psk = "ramenonice";
    };
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
    HHonors = {};
    ihgconnect = {};
  };

  virtualisation.docker.enable = true;
  virtualisation.docker.liveRestore = false;

  virtualisation.virtualbox.host.enable = true;
  virtualisation.virtualbox.host.addNetworkInterface = true;
  virtualisation.virtualbox.guest.enable = true;

  networking.extraHosts =
    ''
      127.0.0.1 janus.development.local
      127.0.0.1 metis.development.local
      127.0.0.1 timur.development.local
      127.0.0.1 magma.development.local
      127.0.0.1 vulcan.development.local
      127.0.0.1 polyphemus.development.local
    '';

  networking.nameservers = [ "10.0.0.14" "1.1.1.1" "8.8.8.8" "8.8.4.4" ];


  security.pki.certificateFiles = (if builtins.pathExists "/home/home/.local/share/mkcert/rootCA.pem" then [
    /home/home/.local/share/mkcert/rootCA.pem
  ] else []);
}
