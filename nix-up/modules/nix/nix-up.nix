{ config, pkgs, ... }:

let

  inherit (pkgs) stdenv;

  writeProgram = name: env: src:
    pkgs.substituteAll ({
      inherit name src;
      dir = "bin";
      isExecutable = true;
    } // env);

  up-option = writeProgram "up-option"
    {
      inherit (config.system) profile;
      inherit (stdenv) shell;
    }
    ../../pkgs/up-option.sh;

  up-rebuild = writeProgram "up-rebuild"
    {
      inherit (config.system) profile;
      inherit (stdenv) shell;
      path = "${pkgs.coreutils}/bin:${config.nix.package}/bin:${config.environment.systemPath}";
    }
    ../../pkgs/up-rebuild.sh;
in

{
  config = {

    environment.systemPackages =
      [ # Include nix-tools by default
        up-option
        up-rebuild
      ];

  };
}
