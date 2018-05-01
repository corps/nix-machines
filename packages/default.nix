self: super:

# Good examples at https://github.com/yegortimoshenko/overlay/blob/master/pkgs/default.nix
let callPackage = super.newScope self; in rec {
  dropbox_uploader = callPackage ./dropbox_uploader {};
  ngrok = callPackage ./ngrok {};
  xhelpers = callPackage ./xhelpers.nix {};
  rip-song = callPackage ./rip-song.nix { inherit dropbox_uploader; };
  freeciv = callPackage ./freeciv.nix {};
  my_neovim = callPackage ./vim {};
  fetch_from_github = callPackage ./fetch-from-github.nix {};
  jupyter = callPackage ./jupyter {};
  universal-ctags = callPackage ./universal-ctags.nix {};

  npmPackages = callPackage ./npm-packages {};

  js-beautify = npmPackages."js-beautify";
  prettier = npmPackages.prettier;
  uglifyjs = npmPackages."uglify-js";
  qrcode-svg = npmPackages."qrcode-svg";

  canto-input = callPackage ./mac_cantonese {};
  iterm2 = callPackage ./iterm2.nix {};
  bensrs = callPackage ./bensrs.nix {};
  corpsLib = super.callPackage ./lib {};
  make-tmpfs = callPackage ./make-tmpfs.nix {};
  tiddly = callPackage ./tiddly {};
  upgrade-packages = callPackage ./upgrade-packages {};

  fetch_from_pypi = callPackage ./fetch-from-pypi.nix {};
  git-dropbox = callPackage ./git-dropbox.nix {};
}

  #   inherit (super.darwin.apple_sdk.frameworks) Carbon Cocoa ApplicationServices;
  #   imagemagick = super.imagemagick;
