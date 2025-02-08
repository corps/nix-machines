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
    shift + cmd - 0x2F : open -a "Visual Studio Code"
  '';
  # shift + cmd - 0x2C : open -a Pycharm

  programs.alacritty.settings = {
    font = {
      normal.family = "CodeNewRoman Nerd Font Mono";
      size = 16;
      bold = {
        style = "Bold";
      };
    };

    window.padding = {
      x = 2;
      y = 2;
    };
    window.decorations = "Full";
    window.opacity = 0.5;
    window.blur = true;
    keyboard.bindings = [
      {
        key = "[";
        mods = "Command|Shift";
        action = "ReceiveChar";
      }
      {
        key = "]";
        mods = "Command|Shift";
        action = "ReceiveChar";
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
