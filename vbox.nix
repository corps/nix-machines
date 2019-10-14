{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/vbox
  ];

  environment.systemPackages = with pkgs; [
    ngrok
    bring-to-front
    redis
  ];
}
