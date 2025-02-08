{
  ...
}:

{
  system.stateVersion = 5;
  nixpkgs.hostPlatform = "aarch64-darwin";
  services.nix-daemon.enable = true;
  environment.development.enable = true;

  imports = [
    ../modules/darwin.nix
  ];

  services.skhd.skhdConfig = ''
    shift + cmd - d    : open -a "Safari"
    shift + cmd - e    : open -a "Alacritty"
    shift + cmd - 0x2C : open -a "Visual Studio Code"
    shift + cmd - 0x2F : open -a Neovide
  '';
}
