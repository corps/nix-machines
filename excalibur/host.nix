{ pkgs, ... }:
{
  imports = [ ../modules/nixos.nix ];
  networking.firewall.allowedTCPPorts = [
    8991
  ];

  systemd.services.nvim-server = {
    enable = true;
    unitConfig = {
      type = "Simple";
    };

    serviceConfig = {
      ExecStart = "${pkgs.nvim}/bin/nvim --listen 8991 --headless";
    };

    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
  };
}
