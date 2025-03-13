{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  cfg = config.programs.gcc;
in

{

  options = {
    programs.gcc = {
      default = mkOption {
        type = types.package;
        default = pkgs.gcc;
        description = "Default gcc to be provided";
      };
    };
  };

  config = {
    environment = {
      systemPackages = with pkgs; [
        cfg.default
        pkg-config
      ];
    };
  };
}
