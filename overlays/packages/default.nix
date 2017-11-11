self: super:

# Good examples at https://github.com/yegortimoshenko/overlay/blob/master/pkgs/default.nix
let callPackage = super.newScope self; in {
  dropbox_uploader = callPackage ./dropbox_uploader.nix {};
  ngrok = callPackage ./ngrok.nix {};
  xhelpers = callPackage ./xhelpers.nix {};
  corpscripts = callPackage ./scripts.nix {};
  freeciv = callPackage ./freeciv.nix {};
  my_neovim = callPackage ./vim {};
  fetch_from_github = callPackage ./fetch-from-github.nix {};
  uglifyjs = (callPackage ./uglifyjs {})."uglify-js-3.1.0";
  # sudo-prompt = (callPackage ./sudo-prompt {})."sudo-prompt-7.1.1";
  jupyter = callPackage ./jupyter {};
  universal-ctags = callPackage ./universal-ctags.nix {};
  prettier = (callPackage ./prettier {})."prettier-1.7.4";
}
