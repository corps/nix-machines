{ pkgs }:
let plugins = pkgs.callPackage ./plugins.nix {};
in {
  customRC = ''${builtins.readFile ./vimrc}'';
  vam = {
    knownPlugins = pkgs.vimPlugins // plugins;
    pluginDictionaries = [{
      names = [
        "denite-nvim"
        "deoplete-nvim"
        # "editorconfig-vim"

        "vim-commentary"

        "incsearch-fuzzy-vim"
        "incsearch-vim"

        "indent-guide"

        "neoformat"
        "neomake"

        "neovim-fuzzy"
        "nvim-typescript"

        "psc-ide-vim"
        "purescript-vim"
        "syntastic"

        # "sourcebeautify-vim"

        "supertab"

        "vim-airline"
        "vim-airline-themes"

        "vim-buffergator"
        # "vim-eunuch"

        # "vim-fetch"
        # "vim-grepper"

        "vim-polyglot"

        # "nerdtree"

        # for the color scheme
        # "vim-srcery"

        # Haskell
        "neovim-haskell"
        "vim-hindent"
        "intero"
        "neco-ghc"

        "solarized8"


        # "vim-surround"
      ];
    }];
  };
}
