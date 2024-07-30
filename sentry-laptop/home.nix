{ config, lib, pkgs, inputs, ... }:

let
ngrok2 = pkgs.callPackage ../ngrok {};
tfenv = inputs.tfenv;
easy-ps = inputs.easy-purescript-nix.packages.${pkgs.system};
python312Linked = pkgs.stdenv.mkDerivation {
  name = "python312";
  nativeBuildInputs = [ pkgs.python312 ];

  phases = [ "installPhase" ];

  installPhase = ''
    mkdir -p $out/bin
    ln -s ${pkgs.python312}/bin/python $out/bin/python3.12
  '';
};
brewStub = pkgs.writeScriptBin "brew" ''
#! ${pkgs.bash}/bin/bash
echo brew $@
'';

gnuGrepStub = pkgs.writeScriptBin "ggrep" ''
#! ${pkgs.bash}/bin/bash
echo ${pkgs.gnugrep}/bin/grep $@
'';

in

{
  imports = [
    ../modules/darwin
  ];

  services.nix-daemon.enable = true;
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 0; Minute = 0; };
    options = "--delete-older-than 14d";
  };

  nixpkgs.hostPlatform = "aarch64-darwin";

  environment.systemPackages = with pkgs; [
    ngrok2
    neovim
    nnn
    git
    gnused
    gnuGrepStub
    direnv
    openssl
    pkg-config
    watchman
    google-cloud-sdk
    lzma
    ncurses
    readline
    perl

    python311
    python312Linked
    tflint
    tenv

    brewStub

    pkgs.nodejs-18_x
    pkgs.esbuild
    easy-ps.purs-0_15_15
    easy-ps.spago
    easy-ps.purescript-language-server
    easy-ps.purs-tidy
  ];

  environment.shells = [ pkgs.bashInteractive ];
  programs.bash.enable = true;
  programs.bash.enableCompletion = true;

  services.skhd.skhdConfig = ''
shift + cmd - d : open -a "Firefox"
shift + cmd - e : open -a "iTerm"
shift + cmd - 0x2F : open -a Pycharm
shift + cmd - 0x2C : open -a Pycharm
  '';

  # # system.symlinks."$HOME/.config/alacritty/alacritty.yml" = toString ./dotfiles/alacritty.yml;
  # system.userProfile = ''
  #  ln -s $HOME/.confg/alacritty/alacritty.yml ${./dotfiles/alacritty.yml}
  # '';
}
