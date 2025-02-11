{ pkgs, lib, ... }:

{
  home.stateVersion = "20.09";
  environment.development.enable = true;

  imports = [ ../modules/home.nix ];

  environment.variables = {
    NIX_LD_LIBRARY_PATH = with pkgs; lib.makeLibraryPath [
      stdenv.cc.cc
      openssl
      zlib
    ];
    NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
  };

  systemd.user.services.nvim-server = {
    Unit = {
      After = [ "network.target" ];
    };
    Service = {
      Restart = "always";
      ExecStart = "${pkgs.bash}/bin/bash -l -c start-nvim-server.sh";
    };

    Install = {
      WantedBy = [ "multi-user.target" ];
    };
  };
}
