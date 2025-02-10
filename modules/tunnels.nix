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
        command = mkOption {
          type = types.either (types.listOf (types.str)) types.bool;
          default = false;
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
            ProgramArguments =
              [
                "ssh"
              ]
              ++ (if def.command then [ ] else [ "-N" ])
              ++ [
                "-L"
                "${toString def.localPort}:localhost:${toString def.remotePort}"
                def.host
              ]
              ++ (if def.command then def.command else [ ]);
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
