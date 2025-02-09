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
    shift + cmd - 0x2C : open -a "/Applications/Neovide.app/Contents/MacOS/neovide --server localhost:8991"
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
