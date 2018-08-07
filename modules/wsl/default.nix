{ config, lib, pkgs, ... }:

let

setupWin = ''
export WINHOME=$(wslpath $(cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r\n'))
MNTC=$(echo $WINHOME | grep -o -e "[^U]*\/" | head -n 1)
export MNTC=$(echo $MNTC | rev | cut -c 2- | rev)
'';

in

{
  imports = [
    ../shared
    ./autohotkeys.nix
  ];

  environment.extraInit = setupWin;
  programs.autohotkey.enable = true;

  system.activationScripts.preUserActivation.text = setupWin;
}
