{ config, pkgs, ... }:

let 
  ngrokConfig = pkgs.writeText "ngrok.yml" (pkgs.lib.generators.toYAML {} {
    tunnels = {
      http = {
        proto = "http";
        addr = 3000;
        inspect = false;
        # hostname = "*.me.com";
      };
    };
  });

  ngrok = pkgs.callPackage ../packages/ngrok {};
in

{
  imports = [
    ../modules/nixos/docker-services.nix
  ];

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
    ngrok
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

  systemd.services."ngrok" = {
    description = "Ngrok reverse proxy";
    wantedBy = [ "multi-user.target" ];
    # restartTriggers = [];
    serviceConfig = { 
      ExecStart = "${ngrok}/bin/ngrok start -config /etc/secrets/ngrok.yml -config ${ngrokConfig} --all";
    };
  };

  dockerServices.watchtower = {
    image = "containrrr/watchtower";
    tag = "latest";
    cmd = "";
    options = [
      "-v /var/run/docker.sock:/var/run/docker.sock"
    ];
  };
}
