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

  wsl-run = writeProgram "wsl-run"
    {
      inherit (stdenv) shell;
    }
    ../../pkgs/wsl-run.sh;

  wsl-rund = writeProgram "wsl-rund"
    {
      inherit (stdenv) shell;
    }
    ../../pkgs/wsl-rund.sh;

in

{
  config = {

    environment.systemPackages =
      [ # Include nix-tools by default
        wsl-option
        wsl-rebuild
        wsl-run
        wsl-rund
      ];

  };
}
