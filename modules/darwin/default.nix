{ config, lib, pkgs, ... }:

let
compostPkgs = (import ../../compost) { inherit pkgs; compostScript = "darwin-compost.sh"; };
activate-window = (import ./activate-window.nix) { inherit pkgs; };

in


{
  imports = [
    ./keybindings.nix
    ./supervisord.nix
    ./workspaces.nix
  ];

  system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = 1;
  system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "left";
  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder._FXShowPosixPathInTitle = true;
  system.defaults.dockEx."workspaces-edge-delay" = "0.0";

  environment.systemPackages = with pkgs; with compostPkgs; [
    compost
    nixfmt-rfc-style
    update-channels
    activate-window
  ];

  nix = {
    package = pkgs.nix;
    settings = {
      "extra-experimental-features" = [ "nix-command" "flakes" ];
    };
  };
}
