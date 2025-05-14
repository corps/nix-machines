{
  ...
}:

{
  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";

  imports = [
    ../modules/darwin.nix
  ];

  services.skhd.skhdConfig = ''
    shift + cmd - d    : open -a "Google Chrome"
    shift + cmd - e    : open -a "Alacritty"
    shift + cmd - 0x2C : open -a "PyCharm"
  '';
}
