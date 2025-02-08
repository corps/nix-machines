{
  config,
  lib,
  pkgs,
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
  options = {
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
    environment.systemPackages = (if config.programs.alacritty.enable then [ pkgs.alacritty ] else [ ]);
    system.activationScripts.extraUserActivation.text = (
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
