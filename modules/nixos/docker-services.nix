{ config, lib, pkgs, ... }:

with lib;

let

dockerService = {
  options = {
    image = mkOption {
      type = types.string;
      description = "Image to use";
    };
    
    tag = mkOption {
      type = types.string;
      default = "latest";
    };

    cmd = mkOption {
      type = types.string;
    };

    options = mkOption {
      type = types.listOf types.string;
      default = [];
    };

    unit = mkOption {
      type = types.attrsOf types.string;
      default = {};
    };

    service = mkOption {
      type = types.attrsOf types.string;
      default = {};
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
      dsConf = config.dockerServices[k]; 
      optionsJoined = lib.concatStringsSep " " dsConfig.options;
      runOptions = "--name ${k} ${optionsJoined} ${dsConf.image}:${dsConf.tag} ${dsConf.cmd}";
    in {
      description = "Wrapped service running ${dsConf.image}:${dsConf.tag}";
      wantedBy = [ "multi-user.target" ];
      after = [ "docker.service" ];
      requires = [ "docker.service" ];
      serviceConfig = {
        Type = "simple";
        User = "root";
        WorkingDirectory = "/root";
        Restart = "always";
        RestartSec = "3";
        ExecStart = "/run/current-system/sw/bin/docker run --rm ${runOptions}";
      } // dsConf.service;
    } // dsConf.unit;
  }) (builtins.attrNames config.dockerServices));
}
