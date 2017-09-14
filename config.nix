{ pkgs }: {
  packageOverrides = super:
    let self = super.pkgs;
        pkg = pkgs.callPackage;
    in
  with self; rec {
    dropbox_uploader = pkg ./packages/dropbox_uploader.nix {};
    ngrok = pkg ./packages/ngrok.nix {};
    xhelpers = pkg ./packages/xhelpers.nix {};
    corpscripts = pkg ./packages/scripts.nix {};
    freeciv = pkg ./packages/freeciv.nix {};
    my_neovim = pkg ./packages/vim {};
    fetch_from_github = pkg ./packages/fetch-from-github.nix {};
    uglifyjs = (pkg ./packages/uglifyjs {})."uglify-js-3.1.0";
  };

  allowUnfree = true;
  vim.ftNix = false; # http://nicknovitski.com/vim-nix-syntax
}
