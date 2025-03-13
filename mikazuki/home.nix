{ pkgs, lib, ... }:

{
  home.stateVersion = "24.11";
  imports = [ ../modules/home.nix ];

  systemd.user.services.nvim-server = {
    Unit = {
      After = [ "network.target" ];
    };
    Service = {
      Restart = "always";
      ExecStart = "${pkgs.bash}/bin/bash -l -c /home/home/nix-machines/bin/start-nvim-server.sh";
    };

    Install = {
      WantedBy = [ "multi-user.target" ];
    };
  };
}
