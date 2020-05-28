self: super:

# Good examples at https://github.com/yegortimoshenko/overlay/blob/master/pkgs/default.nix
let callPackage = super.newScope self; in rec {
  ngrok = callPackage ./ngrok {};
  bring-to-front = callPackage ./bring-to-front.nix {};
  my_neovim = callPackage ./vim {};
  fetch_from_github = callPackage ./fetch-from-github.nix {};
  jupyter = callPackage ./jupyter {};
  universal-ctags = callPackage ./universal-ctags {};
  corpsLib = super.callPackage ./lib {};
  make-tmpfs = callPackage ./make-tmpfs.nix {};
  upgrade-packages = callPackage ./upgrade-packages {};
  fetch_from_pypi = callPackage ./fetch-from-pypi.nix {};
  wintmp = callPackage ./wintmp.nix {};
  nix-pkgs-pinner = callPackage ./nix-pkgs-pinner.nix {};
  alacritty = (import <unstable> { overlays = []; }).alacritty;
  activate-window = callPackage ./activate-window.nix {};

  bring-to-front-desktop = callPackage ./bring-to-front-desktop.nix {};
}
  #   inherit (super.darwin.apple_sdk.frameworks) Carbon Cocoa ApplicationServices;
  #   imagemagick = super.imagemagick;
