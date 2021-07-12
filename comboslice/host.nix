{ config, pkgs, ... }:

let 
  ngrokConfig = pkgs.writeText "ngrok.yml" (pkgs.lib.generators.toYAML {} {
    tunnels = {
      tfm = {
        proto = "http";
        addr = 9009;
        inspect = false;
        hostname = "z-tfm.ngrok.io";
      };

      bensrs = {
        proto = "http";
        addr = 8083;
        inspect = false;
        hostname = "bensrs.ngrok.io";
      };
    };
  });
in

{
  imports = [
    ../modules/nixos/server.nix
  ];

  environment.systemPackages = with pkgs; [
    fava
    neovim 
    beancount
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

    virtualHosts."fava.comboslice.local" = {
      forceSSL = true;
      sslCertificate = /home/home/.local/share/mkcert/_wildcard.comboslice.local.pem;
      sslCertificateKey = /home/home/.local/share/mkcert/_wildcard.comboslice.local-key.pem;
      locations."/".proxyPass = "http://localhost:5000";
    };

    virtualHosts."benyt.comboslice.local" = {
      forceSSL = true;
      sslCertificate = /home/home/.local/share/mkcert/_wildcard.comboslice.local.pem;
      sslCertificateKey = /home/home/.local/share/mkcert/_wildcard.comboslice.local-key.pem;
      locations."/".proxyPass = "http://localhost:3009";
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
    serviceConfig = { 
      ExecStart = "${pkgs.ngrok}/bin/ngrok start -config /secrets/ngrok/auth.yml -config ${ngrokConfig} --all";
      Restart="always";
    };
  };

  systemd.services."accounting-deploy" = {
    description = "Updates the accounting file";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.bash pkgs.git ];
    serviceConfig = {
      Type="simple";
      User="home";
      Group="users";
      WorkingDirectory="/home/home/accounting";
      Restart="always";
      ExecStart = "/home/home/.nix-profile/bin/run-on-git-update /run/wrappers/bin/sudo systemctl restart accounting-fava";
    };
  };

  systemd.services."bensrs-deploy" = {
    description = "Updates the bensrs source";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.bash pkgs.git ];
    serviceConfig = {
      Type="simple";
      User="home";
      Group="users";
      Environment=["BRANCH=master" "PATH=/run/current-system/sw/bin:/home/home/.nix-profile/bin:/run/wrappers/bin"];
      WorkingDirectory="/home/home/ben-srs";
      Restart="always";
      ExecStart = "/home/home/.nix-profile/bin/run-on-git-update docker-build-and-push localhost:5050/bensrs";
    };
  };

  systemd.services."terraforming-mars-deploy" = {
    description = "Updates the terraforming-mars source";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.bash pkgs.git ];
    serviceConfig = {
      Type="simple";
      User="home";
      Group="users";
      Environment=["BRANCH=main" "PATH=/run/current-system/sw/bin:/home/home/.nix-profile/bin:/run/wrappers/bin"];
      WorkingDirectory="/home/home/terraforming-mars";
      Restart="always";
      ExecStart = "/home/home/.nix-profile/bin/run-on-git-update docker-build-and-push localhost:5050/terraforming-mars";
    };
  };

  systemd.services."accounting-fava" = {
    description = "Fava server for accounting";
    wantedBy = [ "multi-user.target" ];
    path = [ pkgs.fava ];
    serviceConfig = {
      Type="simple";
      User="home";
      Group="users";
      Restart="always";
      ExecStart = "/usr/bin/env fava /home/home/accounting/master.bean";
    };
  };
  
  dockerServices.watchtower = {
    image = "containrrr/watchtower";
    tag = "latest";
    cmd = "";
    options = [
      "-v /var/run/docker.sock:/var/run/docker.sock"
      "-v /home/home/.docker/config.json:/config.json"
      "-e 'WATCHTOWER_NOTIFICATIONS=email'"
      "-e 'WATCHTOWER_NOTIFICATION_EMAIL_FROM=recursive.cookie.jar@gmail.com'"
      "-e 'WATCHTOWER_NOTIFICATION_EMAIL_TO=recursive.cookie.jar@gmail.com'"
      "-e 'WATCHTOWER_NOTIFICATION_EMAIL_SERVER=smtp.gmail.com'"
      "-e 'WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PORT=587'"
      "-e 'WATCHTOWER_NOTIFICATION_EMAIL_SERVER_USER=recursive.cookie.jar@gmail.com'"
      "-e 'WATCHTOWER_NOTIFICATION_EMAIL_SERVER_PASSWORD=${import /secrets/gmail/app_password.nix}'"
      "-e 'WATCHTOWER_NOTIFICATION_EMAIL_SUBJECTTAG=comboslice'"
      "-e 'WATCHTOWER_POLL_INTERVAL=1500'"
      "-e 'WATCHTOWER_NO_STARTUP_MESSAGE=1'"
      "-e 'WATCHTOWER_INCLUDE_STOPPED=1'"
      "-e 'WATCHTOWER_INCLUDE_RESTARTING=1'"
      "-e 'WATCHTOWER_NO_RESTART=1'"
    ];
  };

  # "'--label=com.centurylinklabs.watchtower.enable=false'"

  # dockerServices.dropbox = {
  #   image = "otherguy/dropbox";
  #   tag = "latest";
  #   cmd = "";
  #   options = [
  #     "-e TZ=America/Los_Angeles"
  #     "-e DROPBOX_UID=1000"
  #     "-e DROPBOX_GID=100"
  #     "-v /dbox:/opt/dropbox/Dropbox"
  #     "-v /dbox.settings:/opt/dropbox/.dropbox"
  #   ];
  # };

  dockerServices."terraforming-mars" = {
    image = "localhost:5050/terraforming-mars";
    tag = "latest";
    cmd = "";
    options = [
      "-p 9009:8080"
    ];
  };

  dockerServices."bensrs" = {
    image = "localhost:5050/bensrs";
    tag = "latest";
    cmd = "websocketd --port 8083 --staticdir docs --cgidir cgi ./server.sh ";
    options = [
      "-p 8083:8083"
      "-e 'PW=${import /secrets/bensrs/app_password.nix}'"
    ];
  };

  services.dockerRegistry = {
    enable = true;
    port = 5050;
    enableGarbageCollect = true;
  };

  # systemd.services.gitlab-runner.path = [
  #   "/run/wrappers" # /run/wrappers/bin/su
  #   "/" # /bin/sh
  # ];
  
  # services.gitlab-runner = {
  #   enable = false;
  #   concurrent = 1;

  #   services.shell = {
  #       buildsDir = "/var/lib/gitlab-runner/builds";
  #         executor = "shell";
  #         environmentVariables = {
  #             ENV = "/etc/profile";
  #             USER = "root";
  #             NIX_REMOTE = "daemon";
  #             PATH = "/nix/var/nix/profiles/default/bin:/nix/var/nix/profiles/default/sbin:/bin:/sbin:/usr/bin:/usr/sbin";
  #             NIX_SSL_CERT_FILE = "/nix/var/nix/profiles/default/etc/ssl/certs/ca-bundle.crt";
  #         };
  #         registrationConfigFile = "/secrets/gitlab/runner-env";
  #     };
  # };

  networking.firewall.allowedTCPPorts = [ 23 80 443 53 ];
  networking.firewall.allowedUDPPorts = [ 53 ];
}
