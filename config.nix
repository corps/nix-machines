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
    # sudo-prompt = (pkg ./packages/sudo-prompt {})."sudo-prompt-7.1.1";
    jupyter = pkg ./packages/jupyter {};
    universal-ctags = pkg ./packages/universal-ctags.nix {};
    prettier = (pkg ./packages/prettier {})."prettier-1.7.4";

    recover = {
      inherit jupyter my_neovim fetch_from_github uglifyjs xhelpers corpscripts autossh fzy
      imagemagick wget universal-ctags;
    };
    # inherit (pkgs.callPackage ./packages/nix.nix {}) nix;
  };

  allowUnfree = true;
  vim.ftNix = false; # http://nicknovitski.com/vim-nix-syntax
}
