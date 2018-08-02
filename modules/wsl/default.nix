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
    ./nixpkgs.nix
    ./autohotkeys.nix
    ./symlinks.nix
  ];

  environment.extraInit = setupWin;

  environment.variables.EDITOR = "vim";
  environment.variables.LANG = "en_US.UTF-8";

  programs.bash.enable = true;
  programs.autohotkey.enable = true;

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
