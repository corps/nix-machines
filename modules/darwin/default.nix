{ config, lib, pkgs, ... }:

{
  imports = [
    ./keybindings.nix
    ./jupyter.nix
    ./nixpkgs.nix
    ./symlinks.nix
    ./supervisord.nix
    ./input-plugins.nix
    ./workspaces.nix
    ./nativeapps.nix
    ./tiddly.nix
  ];

  environment.systemPackages = with pkgs; [
    upgrade-packages
  ];

  environment.variables.EDITOR = "vim";
  environment.variables.LANG = "en_US.UTF-8";

  programs.bash.enable = true;
  # programs.bash.enableCompletion = true;

  system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = 1;
  system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "left";
  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder._FXShowPosixPathInTitle = true;

  services.supervisord.enable = true;

  nix.nixPath = [
    "darwin-config=$HOME/.nixpkgs/darwin-configuration.nix"
    ("nixpkgs=" + (import ../../packages/darwin-nixpkgs { inherit lib; }))
    "/nix/var/nix/profiles/per-user/root/channels"
    "$HOME/.nix-defexpr/channels"
  ];

  system.activationScripts.extraActivation.text = ''
    (
      set +e
      vim --headless +UpdateRemotePlugins +q
    )
  '';

  nix.package = pkgs.nix;
  services.nix-daemon.enable = true;
  system.activationScripts.checks.text = lib.mkForce "";
}
