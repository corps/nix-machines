{ config, pkgs, ... }:

let

  inherit (pkgs) stdenv;

  writeProgram = name: env: src:
    pkgs.substituteAll ({
      inherit name src;
      dir = "bin";
      isExecutable = true;
    } // env);

  wsl-option = writeProgram "wsl-option"
    {
      inherit (config.system) profile;
      inherit (stdenv) shell;
    }
    ../../pkgs/wsl-option.sh;

  wsl-rebuild = writeProgram "wsl-rebuild"
    {
      inherit (config.system) profile;
      inherit (stdenv) shell;
      path = "${pkgs.coreutils}/bin:${config.nix.package}/bin:${config.environment.systemPath}";
    }
    ../../pkgs/wsl-rebuild.sh;

in

{
  config = {

    environment.systemPackages =
      [ # Include nix-tools by default
        wsl-option
        wsl-rebuild
      ];

  };
}
