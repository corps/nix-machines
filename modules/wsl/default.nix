{ config, lib, pkgs, ... }:

{
  imports = [
    ./nixpkgs.nix
  ];

  environment.variables.EDITOR = "vim";
  environment.variables.LANG = "en_US.UTF-8";
  programs.bash.enable = true;

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
