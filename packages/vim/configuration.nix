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
        "editorconfig-vim"
        "incsearch-fuzzy-vim"
        "incsearch-vim"
        "neoformat"
        "neomake"
        "neovim-fuzzy"
        "nvim-typescript"
        "sourcebeautify-vim"
        "supertab"
        "vim-airline"
        "vim-airline-themes"
        "vim-buffergator"
        "vim-eunuch"
        "vim-fetch"
        "vim-fugitive"
        "vim-go"
        "vim-grepper"
        "vim-javascript"
        "vim-polyglot"
        "vim-rails"
        "vim-ruby"
        "vim-srcery"
        "vim-surround"
        "vimwiki"
      ];
    }];
  };
}
