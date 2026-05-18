{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    programs.neovide.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = {
    environment.systemPackages = (if config.programs.neovide.enable then [ pkgs.neovide ] else [ ]);
  };
}
