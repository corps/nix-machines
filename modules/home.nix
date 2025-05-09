{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;

{
  imports = [
    { _module.args = { inherit inputs; }; }
    ./c.nix
    ./libs.nix
    ./nix.nix
    ./node.nix
    ./purescript.nix
    ./python.nix
    ./rust.nix
    ./tools.nix
    ./lean.nix
    ./lua.nix
    ./vine.nix
  ];
  options = {
    environment.systemPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
    };

    environment.variables = mkOption {
      type = types.attrsOf types.str;
      default = { };
    };

    programs.bash.completion.enable = mkOption {
      type = types.bool;
      default = true;
    };

    programs.bash.interactiveShellInit = mkOption {
      type = types.lines;
      default = "";
    };
  };

  config = {
    nix.package = pkgs.nix;
    home.username = "home";
    home.homeDirectory = "/home/home";
    home.packages = config.environment.systemPackages;
    home.sessionVariables = config.environment.variables // {
      NIX_LD_LIBRARY_PATH =
        with pkgs;
        lib.makeLibraryPath [
          stdenv.cc.cc
          openssl
          zlib
        ];
      NIX_LD = lib.fileContents "${pkgs.stdenv.cc}/nix-support/dynamic-linker";
    };
    programs.bash.enableCompletion = config.programs.bash.completion.enable;
    programs.bash.initExtra =
      config.programs.bash.interactiveShellInit
      + ''
        ${config.lib.shell.exportAll config.home.sessionVariables}
        export PATH=$PATH:$HOME/nix-machines/bin
      '';
  };
}
