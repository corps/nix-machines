
{ config, lib, pkgs, ... }:

{
  hardware = {
    pulseaudio = {
      enable = true;
      support32Bit = true;
      # extraConfig = ''
      #   load-module module-alsa-sink device_id=0 channels=3 channel_map=front-left,front-right,center
      # '';
    };
  };

  environment.systemPackages = with pkgs; [
  ];
}
