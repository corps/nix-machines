{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
let
  compost = import ../compost { inherit pkgs; };
in

{
  imports = [
    ./development.nix
  ];

  config = {
    environment = {
      systemPackages =
        (
          if config.environment.development.enable then
            with pkgs;
            [
              nixd
              nixfmt-rfc-style
            ]
          else
            [ ]
        )
        ++ [ compost ];
    };

    nix = {
      gc =
        {
          automatic = true;
          options = "--delete-older-than 14d";
        }
        // (
          if pkgs.stdenv.isDarwin then
            {
              interval = {
                Weekday = 0;
                Hour = 10;
                Minute = 0;
              };
            }
          else
            { }
        );

      settings = {
        "extra-experimental-features" = [
          "nix-command"
          "flakes"
        ];
      };
    };
  };
}
