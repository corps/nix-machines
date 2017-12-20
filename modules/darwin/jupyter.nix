{ config, lib, pkgs, ... }:

with lib;

let cfg = config.services.jupyter; in

{
  options = {
    services.jupyter.enable = mkOption {
      type = types.bool;
      default = false;
      description = "Wether to enable the jupter launchd agent.";
    };
  };


  config = mkIf cfg.enable {
    launchd.user.agents.jupyter = {
      path = [ pkgs.jupyter config.environment.systemPath ];
      serviceConfig.ProgramArguments = [ "${pkgs.jupyter}/bin/jupyter" ];
      serviceConfig.KeepAlive = false;
      serviceConfig.ProcessType = "Interactive";
    };
  };
}
