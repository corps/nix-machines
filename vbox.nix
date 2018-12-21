{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/vbox
  ];

  environment.systemPackages = with pkgs; [
    ngrok 
  ];
}
