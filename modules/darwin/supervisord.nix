{ config, lib, pkgs, ... }:

with lib;

let 
programs = config.supervisord.programs;
programsCfg = builtins.listToAttrs (map (k: {
  name = "program:${k}";
  value = builtins.removeAttrs (builtins.getAttr k programs) [ "_module" ];
}) (builtins.attrNames programs));
cfg = config.services.supervisord;
supervisorBin = pkgs.python27Packages.supervisor;
supervisorIni = pkgs.writeText "supervisor.ini" (generators.toINI {} (rec {
  inet_http_server = {
    port = "127.0.0.1:${toString cfg.port}";
  };

  supervisorctl = {
    serverurl = "http://${inet_http_server.port}";
  };

  "rpcinterface:supervisor" = {
    "supervisor.rpcinterface_factory" = "supervisor.rpcinterface:make_main_rpcinterface";
  };

  supervisord = {
    logfile = "/tmp/supervisord.log";
    nodaemon = "true";
  };
} // programsCfg));

programMod = {
  options = {
    command = mkOption {
      type = types.string;
    };

    autostart = mkOption {
      type = types.string;
      default = "true";
    };

    startsecs = mkOption {
      type = types.int;
      default = 3;
    };

    startretries = mkOption {
      type = types.int;
      default = 3;
    };

    stdout_logfile = mkOption {
      type = types.string;
    };

    redirect_stderr = mkOption {
      type = types.string;
      default = "true";
    };

    stopwaitsecs = mkOption {
      type = types.int;
      default = 10;
    };
  };
};

in

{
  options = {
    supervisord.programs = mkOption { 
      type = types.attrsOf (types.submodule programMod);
      default = {};
    };

    services.supervisord = {
      port = mkOption {
        type = types.int;
        default = 5200;
      };

      enable = mkOption {
        type = types.bool;
        default = false;
      };
    };
  };

  config = mkIf cfg.enable {
    launchd.user.agents.supervisord = {
      path = [ supervisorBin config.environment.systemPath ];
      serviceConfig.ProgramArguments = [
        "${supervisorBin}/bin/supervisord"
        "-c"
        "${supervisorIni}"
      ];

      serviceConfig.KeepAlive = false;
      serviceConfig.RunAtLoad = true;
      serviceConfig.ProcessType = "Interactive";
      serviceConfig.StandardErrorPath = "/tmp/supervisord.err.log";
    };
  };
}
