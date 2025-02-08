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

  programs.alacritty.settings = {
    font = {
      normal.family = "CodeNewRoman Nerd Font Mono";
      size = 16;
      bold = {
        style = "Bold";
      };
    };
    keyboard.bindings = [
      {
        key = "[";
        mods = "Command|Shift";
        action = "None";
      }
      {
        key = "]";
        mods = "Command|Shift";
        action = "None";
      }
      {
        key = "`";
        mods = "Command";
        action = "SelectNextTab";
      }
      {
        key = "b";
        mods = "Command";
        action = "None";
      }
    ];
    cursor.style = "Beam";
  };
}
