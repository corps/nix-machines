{ config, pkgs, ... }:

{
  home.stateVersion = "20.09";
  environment.development.enable = true;

  imports = [ ../modules/home.nix ];

  systemd.user.services.nvim-server = {
    enable = true;
    unitConfig = {
      type = "Simple";
    };

    serviceConfig = {
      Restart = "always";
      ExecStart = "/usr/bin/env bash -l -c nvim --listen 0.0.0.0:8991 --headless";
    };

    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
  };
}
