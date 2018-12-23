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

  nix.nixPath = [ # Include default path <wsl-config>.
    "wsl=${toString ../../nix-wsl}"
    "wsl-config=$HOME/.nixpkgs/wsl-configuration.nix"
    ("nixpkgs=" + (toString ../../packages/pinned/nixos-18.09))
    "$HOME/.nix-defexpr/channels"
  ];

  environment.extraInit = setupWin;
  programs.autohotkey.enable = true;

  system.activationScripts.preUserActivation.text = setupWin;
}
