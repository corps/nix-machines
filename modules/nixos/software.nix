{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    chromium
    wget
    vim
    gitAndTools.gitFull
    which
    screen
    patchelf
    file
    jre
    ngrok
  ];

  programs = {
    bash.enableCompletion = true;
  };
}
