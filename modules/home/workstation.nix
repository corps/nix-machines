{ config, pkgs, lib, ... }:
let
unstable = import <unstable> {};

ruby-mine = unstable.jetbrains.ruby-mine;
pycharm = unstable.jetbrains.pycharm-professional;
act = unstable.act;
bring-firefox-to-front = pkgs.bring-to-front-desktop "Firefox" "${pkgs.firefox}/bin/firefox";
bring-konsole-to-front = pkgs.bring-to-front-desktop "Konsole" "${pkgs.konsole}/bin/konsole";
bring-rubymine-to-front = pkgs.bring-to-front-desktop "ruby-mine-proj" "${ruby-mine}/bin/ruby-mine";
bring-pycharm-to-front = pkgs.bring-to-front-desktop "pycharm-proj" "${pycharm}/bin/pycharm-professional";
chefdk = unstable.chefdk;
in

{
  imports = [
    ./common.nix
  ];

  home.packages = (with pkgs; [
    bring-to-front
    dropbox
    signal-desktop
    bring-firefox-to-front
    bring-konsole-to-front
    bring-rubymine-to-front
    bring-pycharm-to-front
    pycharm
    ruby-mine
    gnumake
    ucsf-vpn
    kazam
    make-splits
    zoom-us
  ]);

  programs.firefox = {
    enable = true;
    profiles = {
      myprofile = {
        settings = {
          "general.smoothScroll" = false;
        };
      };
    };
  };

  programs.vscode = {
    enable = true;
  };
}
