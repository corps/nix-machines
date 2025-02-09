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
      ExecStart = "${pkgs.neovim}/bin/nvim --listen 0.0.0.0:8991 --headless";
    };

    wantedBy = [ "multi-user.target" ];
    after = [ "network.target" ];
  };
}
