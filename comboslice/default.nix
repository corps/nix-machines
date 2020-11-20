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
    add-bin-to-path
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

  users.users.git = {
    isNormalUser = true;
    extraGroups = [ "docker" ];
  };

  virtualisation.docker.enable = true;

  networking.hostName = "comboslice";

  services.dnsmasq = {
    enable = true;
    resolveLocalQueries = true;
    servers = [
      ''/local/10.0.0.14''
      ''1.1.1.1''
      ''8.8.8.8''
      ''8.8.4.4''
    ];

    extraConfig = ''
      address=/local/10.0.0.14
    '';
  };

  services.nginx = {
    enable = true;
    recommendedGzipSettings = true;
    recommendedOptimisation = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
    virtualHosts."git.comboslice.local" = {
      forceSSL = true;
      sslCertificate = /home/home/.local/share/mkcert/_wildcard.comboslice.local.pem;
      sslCertificateKey = /home/home/.local/share/mkcert/_wildcard.comboslice.local-key.pem;
      locations."/".proxyPass = "http://unix:/run/gitlab/gitlab-workhorse.socket";
    };
  };

  services.gitlab = {
    enable = true;
    databasePasswordFile = "/var/keys/gitlab/db_password";
    initialRootPasswordFile = "/var/keys/gitlab/root_password";
    https = true;
    host = "git.comboslice.local";
    # port = 443;
    user = "git";
    group = "git";
    databaseUsername = "git";
    smtp = {
      enable = false;
      # address = "localhost";
      # port = 25;
    };
    secrets = {
      dbFile = "/var/keys/gitlab/db";
      secretFile = "/var/keys/gitlab/secret";
      otpFile = "/var/keys/gitlab/otp";
      jwsFile = "/var/keys/gitlab/jws";
    };
    extraConfig = {
      gitlab = {
        # email_from = "gitlab-no-reply@example.com";
        # email_display_name = "Example GitLab";
        # email_reply_to = "gitlab-no-reply@example.com";
        # default_projects_features = { builds = false; };
      };
    };
  };


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

  dockerServices.dropbox = {
    image = "oddlid/dropbox";
    tag = "latest";
    cmd = "";
    options = [
      "-v /dbox:/home/dropbox/Dropbox"
    ];
  };
}
