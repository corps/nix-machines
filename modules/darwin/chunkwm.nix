{ config, pkgs, lib, ... }:

with lib;

{
  config = mkIf config.services.chunkwm.enable {
    environment.systemPackages = with pkgs; [
      chunkwm.border
      chunkwm.tiling
    ];

    environment.pathsToLink = [ "/lib/chunkwm" ];

    # HACK!  Requires second build to fix
    system.activationScripts.extraActivation.text = ''
      [ -e /etc/chunkwmrc ] && chmod +x /etc/chunkwmrc
    '';

    services.chunkwm = {
      package = pkgs.chunkwm.core;

      extraConfig = ''
      '';

      plugins.list = [ "border" "tiling" ];

      plugins."border".config = ''
        chunkc set focused_border_color          0xffc0b18b
        chunkc set focused_border_width          4
        chunkc set focused_border_radius         0
        chunkc set focused_border_skip_floating  0
      '';

      plugins."tiling".config = ''
        chunkc set global_desktop_mode           bsp
      '';
    };
  };
}
