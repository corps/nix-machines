{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

let
  tunnelOptions =
    { ... }:
    {
      options = {
        remotePort = mkOption {
          type = types.int;
        };
        localPort = mkOption {
          type = types.int;
        };
        host = mkOption {
          type = types.str;
        };
      };
    };

  cfg = config.services.tunnels;
in

{
  options = {
    services.tunnels.enable = mkOption {
      type = types.bool;
      default = false;
    };

    services.tunnels.definitions = mkOption {
      type = types.listOf (types.submodule tunnelOptions);
      default = [ ];
    };
  };

  config.launchd.user.agents = mkIf cfg.enable (
    foldl (
      acc: def:
      let
        name = "${def.host}${toString def.remotePort}to${toString def.localPort}";
      in
      acc
      // {
        "${name}" = {
          path = [ config.environment.systemPath ];
          serviceConfig = {
            ProgramArguments = [
              "ssh"
              "-N"
              "-R"
              "${toString def.remotePort}:localhost:${toString def.localPort}"
              def.host
            ];
            KeepAlive = true;
            ProcessType = "Background";
            StandardOutPath = "/tmp/${name}.log";
            StandardErrorPath = "/tmp/${name}.err.log";
            RunAtLoad = true;
          };
        };
      }
    ) { } cfg.definitions
  );
}
