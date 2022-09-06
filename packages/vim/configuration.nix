{ pkgs ? import <nixpkgs> {} }:
# let plugins = pkgs.callPackage ./plugins.nix {}; in
{
  customRC = ''${builtins.readFile ./vimrc}'';

  packages.neovimPlugins = with pkgs.vimPlugins; {
    start = [ 
      nvim-lspconfig
      vim-automkdir
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      cmp-calc
      cmp-spell
      cmp-emoji
      cmp-treesitter
      cmp-latex-symbols

      vim-matchup

      vim-commentary
      vim-polyglot
      vim-devicons
      nvim-web-devicons
      vim-shellcheck
      nvim-treesitter
      
      plenary-nvim 
      telescope-nvim

      which-key-nvim
      vim-commentary

      gruvbox-nvim
      # incsearch-fuzzy-vim
      incsearch-vim
      neoformat
        
      # solarized8
      vim-airline
      vim-airline-themes
    ];
  };
  

  # vam = {
    # knownPlugins = pkgs.vimPlugins // plugins;
    # pluginDictionaries = [{
      # names = [
        # "editorconfig-vim"
        # "LanguageClient-neovim"
        # "rust-vim"
      	# "vim-beancount"
        #"indent-guide"
        # "neomake"
        # "neovim-fuzzy"
        # "syntastic"
        # "sourcebeautify-vim"
        #"supertab"
        # "vim-buffergator"
        # "vim-eunuch"
        # "vim-fetch"
        # "vim-grepper"
        # "vim-polyglot"
        # "nerdtree"
        # for the color scheme
        # "vim-srcery"
        # Haskell
        # "neovim-haskell"
        # "vim-hindent"
        # "intero"
        # "neco-ghc"
        # "vim-surround"
	
      # ];
    # }];
  # };
}
