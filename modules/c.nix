{ config, lib, pkgs, ... }:

with lib;
let cfg = config.programs.gcc; in

{
  imports = [
    ./development.nix
  ];

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
      systemPackages = (if config.environment.development.enable then with pkgs; [
        cfg.default
        pkg-config
      ] else []);
    };
  };
}
