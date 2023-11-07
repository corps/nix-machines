{ config, lib, pkgs, ... }:

let
ngrok2 = pkgs.callPackage ../ngrok {};
in

{
  imports = [
    ../modules/darwin
  ];

  environment.systemPackages = with pkgs; [
    ngrok2
    nvim
    bash
    nnn
    git
    runc
    gnused
    pre-commit
    direnv
    openssl
    pkg-config
    add-bin-to-path
    watchman
    google-cloud-sdk
  ];

  environment.shells = [ pkgs.bashInteractive ];
  programs.bash.enable = true;
  programs.bash.enableCompletion = true;

  services.skhd.skhdConfig = ''
shift + cmd - d : open -a "Firefox"
shift + cmd - e : open -a "Terminal"
shift + cmd - 0x2F : open -a Pycharm
shift + cmd - 0x2C : open -a Pycharm
  '';

  # # system.symlinks."$HOME/.config/alacritty/alacritty.yml" = toString ./dotfiles/alacritty.yml;
  # system.userProfile = ''
  #  ln -s $HOME/.confg/alacritty/alacritty.yml ${./dotfiles/alacritty.yml}
  # '';
}
