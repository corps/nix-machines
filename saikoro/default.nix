{ config, lib, pkgs, inputs, ... }:

let
ngrok3 = pkgs.callPackage ../ngrok {};
# easy-ps = inputs.easy-purescript-nix.packages.${pkgs.system};

in

{
  imports = [
    ../modules/darwin
  ];

  services.nix-daemon.enable = true;
  nix.gc = {
    automatic = true;
    interval = { Weekday = 0; Hour = 10; Minute = 0; };
    options = "--delete-older-than 14d";
  };

  # nixpkgs.hostPlatform = "aarch64-darwin";

  environment.systemPackages = with pkgs; [
    ngrok3
    nvim
    nnn
    git
    gnused
    direnv
    openssl
    pkg-config
    watchman
    lzma
    ncurses
    readline
    perl
    ripgrep

    # pkgs.nodejs-18_x
    # pkgs.esbuild
    # easy-ps.purs-0_15_15
    # easy-ps.spago
    # easy-ps.purescript-language-server
    # easy-ps.purs-tidy
  ];

  system.stateVersion = 5;

  environment.shells = [ pkgs.bashInteractive ];
  programs.bash.enable = true;
  programs.bash.enableCompletion = true;
  programs.direnv.enable = true;
  programs.direnv.nix-direnv.enable = true;

#   services.skhd.skhdConfig = ''
# shift + cmd - d : open -a "Firefox"
# shift + cmd - e : open -a "iTerm"
# shift + cmd - 0x2F : open -a Pycharm
# shift + cmd - 0x2C : open -a Pycharm
#   '';
}
