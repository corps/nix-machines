self: super:

# Good examples at https://github.com/yegortimoshenko/overlay/blob/master/pkgs/default.nix
let callPackage = super.newScope self; in rec {
  dropbox_uploader = callPackage ./dropbox_uploader.nix {};
  ngrok = callPackage ./ngrok.nix {};
  xhelpers = callPackage ./xhelpers.nix {};
  rip-song = callPackage ./rip-song.nix { inherit dropbox_uploader; };
  freeciv = callPackage ./freeciv.nix {};
  my_neovim = callPackage ./vim {};
  fetch_from_github = callPackage ./fetch-from-github.nix {};
  uglifyjs = (callPackage ./uglifyjs {})."uglify-js-3.1.0";
  # sudo-prompt = (callPackage ./sudo-prompt {})."sudo-prompt-7.1.1";
  jupyter = callPackage ./jupyter {};
  universal-ctags = callPackage ./universal-ctags.nix {};
  prettier = (callPackage ./prettier {})."prettier-1.7.4";
  js-beautify = (callPackage ./js-beautify {})."js-beautify-1.7.4";
  qrcode-svg = callPackage ./qrcode-svg.nix {};
}
