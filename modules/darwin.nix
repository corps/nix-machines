{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

let
  tomlFormat = pkgs.formats.toml { };
  alacrittyConfig =
    (tomlFormat.generate "alacritty.toml" config.programs.alacritty.settings).overrideAttrs
      (
        finalAttrs: prevAttrs: {
          buildCommand = lib.concatStringsSep "\n" [
            prevAttrs.buildCommand
            "substituteInPlace $out --replace-quiet '\\\\' '\\'"
          ];
        }
      );
in

{
  imports = [
    {
      _module.args = {
        inherit inputs;
      };
    }
    # inputs.home-manager.darwinModules.home-manager
    ./c.nix
    ./libs.nix
    ./nix.nix
    ./node.nix
    ./purescript.nix
    ./python.nix
    ./tools.nix
    ./lean.nix
    ./lua.nix
  ];

  options = {
    programs.git.enable = mkOption {
      default = true;
      type = types.bool;
    };

    programs.git.userName = mkOption {
      default = "Zachary Collins";
      type = types.str;
    };

    programs.git.userEmail = mkOption {
      default = "recursive.cookie.jar@gmail.com";
      type = types.str;
    };

    programs.alacritty.enable = mkOption {
      default = true;
      type = types.bool;
    };

    programs.alacritty.settings = mkOption {
      type = tomlFormat.type;
      default = { };
    };
  };

  config = {
    system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
    system.defaults.dock.autohide = true;

    system.defaults.finder = {
      AppleShowAllExtensions = true;
      AppleShowAllFiles = true;
      FXPreferredViewStyle = "clmv";
      _FXShowPosixPathInTitle = true;
      QuitMenuItem = true;
      ShowStatusBar = true;
      ShowPathbar = true;
    };

    fonts.packages = [ pkgs.nerd-fonts.code-new-roman ];
    environment.shells = [ pkgs.bashInteractive ];
    services.skhd.enable = true;
    environment.systemPackages =
      [
        pkgs.starship
      ]
      ++ (if config.programs.git.enable then [ pkgs.git ] else [ ])
      ++ (if config.programs.alacritty.enable then [ pkgs.alacritty ] else [ ]);
    system.activationScripts.extraUserActivation.text =
      ""
      + (
        if config.programs.git.enable then
          ''
            git config --global user.name ${config.programs.git.userName}
            git config --global user.email ${config.programs.git.userEmail}
          ''
        else
          ""
      )
      + (
        if config.programs.alacritty.enable then
          ''
            mkdir -p "$HOME/.config/alacritty"
            ln -sf /etc/alacritty/alacritty.toml "$HOME/.config/alacritty/alacritty.toml"
          ''
        else
          ""
      );

    environment.etc."alacritty/alacritty.toml" = mkIf config.programs.alacritty.enable {
      source = alacrittyConfig;
    };
  };
}
