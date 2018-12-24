{ config, lib, pkgs, ... }:

{
  imports = [
    ./modules/wsl
  ];

  environment.systemPackages = with pkgs; [
    fetch_from_pypi
    wintmp
    terminator
    font-manager
    xorg.libXrender
    jre8
  ];

  programs.autohotkey.scripts = [
    ./dotfiles/surface-keyboard.ahk
  ];

  system.symlinks."$HOME/.dir_colors" = toString ./dotfiles/dircolors.256dark;

  system.activationScripts.extraUserActivation.text = ''
    set -x
    [[ ! -e ~/.emacs.d ]] && git clone https://github.com/syl20bnr/spacemacs ~/.emacs.d
    set +x
  '';

  # system.activationScripts.extraActivation.text = ''
  # sed -i 's$<listen>.*</listen>$<listen>tcp:host=localhost,port=0</listen>$' /etc/dbus-1/session.conf
  # '';
}
