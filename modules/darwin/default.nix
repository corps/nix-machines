{ config, lib, pkgs, ... }:

{
  imports = [
    ../shared
    ./keybindings.nix
    ./jupyter.nix
    ./supervisord.nix
    ./input-plugins.nix
    ./workspaces.nix
    ./nativeapps.nix
    ./tiddly.nix
  ];

  environment.systemPackages = with pkgs; [
    mitmproxy
  ];

  system.defaults.NSGlobalDomain."com.apple.trackpad.trackpadCornerClickBehavior" = 1;
  system.defaults.NSGlobalDomain.NSDocumentSaveNewDocumentsToCloud = false;
  system.defaults.dock.autohide = true;
  system.defaults.dock.orientation = "left";
  system.defaults.finder.AppleShowAllExtensions = true;
  system.defaults.finder._FXShowPosixPathInTitle = true;
  system.defaults.dockEx."workspaces-edge-delay" = "0.0";

  services.supervisord.enable = true;

  nix.nixPath = [
    "darwin-config=$HOME/.nixpkgs/darwin-configuration.nix"
    ("nixpkgs=" + (toString ../../packages/pinned/nixpkgs-19.03-darwin))
    "/nix/var/nix/profiles/per-user/root/channels"
    "$HOME/.nix-defexpr/channels"
  ];

  nixpkgs.config.vim.ftNix = false;

  nix.package = pkgs.nix;

  services.nix-daemon.enable = true;
  services.jupyter.enable = true;
}
