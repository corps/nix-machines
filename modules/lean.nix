{
  pkgs,
  config,
  lib,
  ...
}:

{
  imports = [ ./development.nix ];

  config = lib.mkIf config.environment.development.enable {
    environment.systemPackages = with pkgs; [ elan ];
  };
}