{ config, lib, pkgs, ... }:

let

setupWin = ''
export WINHOME=$(echo $PATH | grep -o -E "[^:]*\/Users\/[^\/]*" | head -n 1)
MNTC=$(echo $WINHOME | grep -o -e "[^U]*\/" | head -n 1)
export MNTC=$(echo $MNTC | rev | cut -c 2- | rev)
'';

in

{
  imports = [
    ./nixpkgs.nix
    ./chocolatey.nix
  ];

  environment.extraInit = setupWin;

  environment.variables.EDITOR = "vim";
  environment.variables.LANG = "en_US.UTF-8";

  programs.bash.enable = true;
  programs.chocolatey.config = toString ../../packages/chocolatey/packages.config;
  programs.chocolatey.enable = true;

  system.activationScripts.preUserActivation.text = setupWin;
  system.activationScripts.extraUserActivation.text = ''
    (
      set +e
      vim --headless +UpdateRemotePlugins +q
    )
  '';

  environment.systemPackages = with pkgs; [
    upgrade-packages
  ];
}
