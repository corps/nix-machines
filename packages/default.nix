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
  uglifyjs = (callPackage ./uglifyjs {})."uglify-js-3.1.0";
  jupyter = callPackage ./jupyter {};
  universal-ctags = callPackage ./universal-ctags.nix {};
  prettier = (callPackage ./prettier {})."prettier-1.7.4";
  js-beautify = (callPackage ./js-beautify {})."js-beautify-1.7.4";
  qrcode-svg = callPackage ./qrcode-svg.nix {};
  canto-input = callPackage ./mac_cantonese {};
  iterm2 = callPackage ./iterm2.nix {};
  bensrs = callPackage ./bensrs.nix {};
  corpsLib = super.callPackage ./lib {};
  make-tmpfs = callPackage ./make-tmpfs.nix {};
  tiddly = callPackage ./tiddly {};
}

  #   inherit (super.darwin.apple_sdk.frameworks) Carbon Cocoa ApplicationServices;
  #   imagemagick = super.imagemagick;
