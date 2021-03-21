{ config, lib, pkgs, ... }:

with lib;

let

dockerService = {
  options = {
    image = mkOption {
      type = types.str;
      description = "Image to use";
    };
    
    tag = mkOption {
      type = types.str;
      default = "latest";
    };

    cmd = mkOption {
      type = types.str;
      default = "";
    };

    options = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    unit = mkOption {
      type = types.attrsOf types.str;
      default = {};
    };

    service = mkOption {
      type = types.attrsOf types.str;
      default = {};
    };

    runEvery = mkOption {
      type = types.nullOr types.int;
      default = null;
    };
  };
};

in

{
  options = {
    dockerServices = mkOption {
      type = types.attrsOf (types.submodule dockerService);
      default = {};
    };
  };

  config.systemd.services = builtins.listToAttrs (map (k: {
    name = k;
    value = let 
      dsConf = config.dockerServices."${k}"; 
      watchtowerEnabledOptions =
        if dsConf.runEvery == null then [] else
        ["'--label=com.centurylinklabs.watchtower.enable=false'"];
      installOptions = if dsConf.runEvery == null 
        then {wantedBy = ["multi-user.target"]; after = ["docker.service"];}
        else {};
      optionsJoined = lib.concatStringsSep " " (dsConf.options ++ watchtowerEnabledOptions);
      runOptions = "--name ${k} ${optionsJoined} ${dsConf.image}:${dsConf.tag} ${dsConf.cmd}";
    in {
      description = "Wrapped service running ${dsConf.image}:${dsConf.tag}";
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        WorkingDirectory = "/root";
        Restart = "always";
        RestartSec = "3";
        ExecStartPre = "-/run/current-system/sw/bin/docker stop ${k}";
        ExecStop = "/run/current-system/sw/bin/docker stop ${k}";
        ExecStart = "/run/current-system/sw/bin/docker run --rm ${runOptions}";
      } // dsConf.service;
    } // dsConf.unit // installOptions;
  }) (builtins.attrNames config.dockerServices));

  config.systemd.timers = builtins.listToAttrs (filter (v: v.name != null) (map (k:
    let
      dsConf = config.dockerServices."${k}"; 
      runEvery = dsConf.runEvery;
    in
    if runEvery == null then { name = null; } else {
    name = k;
    value = {
      description = "Runs ${k}.service every ${runEvery} seconds";
      wantedBy = [ "multi-user.target" ];
      timerConfig = {
        OnActiveSec= "${runEvery}";
        Unit= "${k}.service";
        OnUniActiveSec= "${runEvery}";
      };
    };
  }) (builtins.attrNames config.dockerServices)));
}
