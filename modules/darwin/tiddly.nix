{ config, lib, pkgs, ... }:

with lib;

let
cfg = config.services.tiddly;
in

{
  options = {
    services.tiddly.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Wether to enable the tiddly wiki server";
    };
  };

  config = mkIf cfg.enable {
    supervisord.programs.tiddly = {
      command = "${pkgs.tiddly}/bin/tiddly";
      startsecs = 5;
      stopwaitsecs = 20;
      stdout_logfile = "/tmp/tiddly.log";
    };
  };
}
