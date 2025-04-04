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
    shift + cmd - d    : open -a "Safari"
    shift + cmd - e    : open -a "Alacritty"
    shift + cmd - 0x2C : open -a "Visual Studio Code"
    shift + cmd - 0x2F : open -a Neovide
  '';

  services.tunnels = {
    enable = true;
    definitions = [
      {
        remotePort = 8991;
        localPort = 8991;
        host = "excalibur";
      }
    ];
  };
}
