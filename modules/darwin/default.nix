{ config, lib, pkgs, ... }:

{
  imports = [
    ./keybindings.nix
    # ./jupyter.nix
    # ./supervisord.nix
    # ./input-plugins.nix
    ./workspaces.nix
    # ./nativeapps.nix
    # ./tiddly.nix
  ];

  environment.systemPackages = with pkgs; [];

  system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = 1;
  system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "left";
  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder._FXShowPosixPathInTitle = true;
  system.defaults.dockEx."workspaces-edge-delay" = "0.0";

  nixpkgs.overlays = [ (import ../../packages) ];


  nix.package = pkgs.nix;
  services.nix-daemon.enable = true;
}
