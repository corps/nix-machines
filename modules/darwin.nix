{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

let
  gitConfigInvocations =
    let
      recurse =
        path: attrs:
        if lib.isAttrs attrs && !lib.isDerivation attrs then
          lib.concatMap (x: x) (lib.mapAttrsToList (k: v: recurse ([ k ] ++ path) v) attrs)
        else
          [
            "git config --global ${lib.concatStringsSep "." (lib.reverseList (lib.tail path))}.${lib.head path} ${attrs}"
          ];
    in
    config: lib.concatStringsSep "\n" (recurse [ ] config);

  gitIniType =
    with lib.types;
    let
      primitiveType = either str (either bool int);
      multipleType = either primitiveType (listOf primitiveType);
      sectionType = attrsOf multipleType;
      supersectionType = attrsOf (either multipleType sectionType);
    in
    attrsOf supersectionType;
in

with lib;

{
  imports = [
    {
      _module.args = {
        inherit inputs;
      };
    }
    # inputs.home-manager.darwinModules.home-manager
    ./alacritty.nix
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
    ./tunnels.nix
    ./vine.nix
  ];

  options = {
    programs.git.enable = mkOption {
      default = true;
      type = types.bool;
    };

    programs.git.lfs.enable = mkOption {
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

    programs.git.extraConfig = mkOption {
      type = types.either types.lines gitIniType;
      default = { };
    };
  };

  config = {
    environment.systemPath = [ "$HOME/nix-machines/bin" ];
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
      (if config.programs.git.enable then [ pkgs.git ] else [ ])
      ++ (if config.programs.git.lfs.enable then [ pkgs.git-lfs ] else [ ]);
    system.activationScripts.extraUserActivation.text =
      ""
      + (
        if config.programs.git.enable then
          ''
            git config --global user.name ${config.programs.git.userName}
            git config --global user.email ${config.programs.git.userEmail}
          ''
          + (gitConfigInvocations config.programs.git.extraConfig)
        else
          ""
      );

    programs.alacritty.enable = true;
  };
}
