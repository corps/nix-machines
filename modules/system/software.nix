{ config, lib, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wget
    vim
    gitAndTools.gitFull
    which
    screen
    patchelf
    file
    jre
  ];

  nixpkgs.config = {
    allowUnfree = true;
    chromium = {
      enablePepperFlash = true;
      enablePepperPDF = true;
    };
  };

  programs = {
    bash.enableCompletion = true;
  };
}
