{
  imports = [
    ./keybindings.nix
    ./jupyter.nix
    ./nixpkgs.nix
    ./symlinks.nix
    ./supervisord.nix
    ./input-plugins.nix
    ./chunkwm.nix
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
}
