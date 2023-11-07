{ config, lib, pkgs, ... }:

with lib;

let
cfg = config.services.jupyter;
in

{
  options = {
    services.jupyter.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Wether to enable the jupyter server";
    };
  };


  config = mkIf cfg.enable {
    supervisord.programs.jupyter = {
      command = "${pkgs.jupyter}/bin/jupyter";
			startsecs = 10;
      stopwaitsecs = 20;
      stdout_logfile = "/tmp/jupyter.log";
    };
  };
}
