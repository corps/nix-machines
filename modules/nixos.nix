{
  config,
  pkgs,
  lib,
  ...
}:

with lib;

{
    environment.systemPackages = with pkgs; [ vim wget curl bash ];
    networking.firewall.enable = true;

    networking.firewall.allowedTCPPorts = [
      80
      443
      22
      2377
      7946
    ];

    virtualisation.docker.enable = true;
    virtualisation.docker.liveRestore = false;
    virtualisation.docker.autoPrune = {
      enable = true;
      dates = "daily";
    };

    networking.firewall.trustedInterfaces = [
      "docker0"
      "docker_gwbridge"
    ];
    networking.firewall.allowedUDPPorts = [
      4789
      7946
    ];

    networking.nameservers = [
      "1.1.1.1"
      "8.8.8.8"
      "8.8.4.4"
    ];

    services.openssh.enable = true;
    services.openssh.settings = {
      GatewayPorts = "yes";
      PasswordAuthentication = false;
    };

    security.sudo.extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/systemctl";
            options = [
              "SETENV"
              "NOPASSWD"
            ];
          }
        ];
      }
    ];

    security.pki.certificateFiles = (
      if builtins.pathExists "/home/home/.local/share/mkcert/rootCA.pem" then
        [
          /home/home/.local/share/mkcert/rootCA.pem
        ]
      else
        [ ]
    );

    users.extraUsers.home = {
      isNormalUser = true;
      extraGroups = [
        "wheel"
        "networkmanager"
        "docker"
      ];
      openssh.authorizedKeys.keys = (import ./authorized-keys.nix).github.corps;
    };

    networking.wireless.userControlled.enable = true;
    # networking
    networking.wireless.networks = {
      projector = {
        psk = "ramenonice";
      };
      UCSFguest = { };
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
        psk = "Awesome!!!!";
      };
      "Hilton Honors" = { };
      HHonors = { };
      ihgconnect = { };
    };

    time.timeZone = "America/Los_Angeles";
    boot.kernel.sysctl."fs.inotify.max_user_instances" = 2147483647;
}
