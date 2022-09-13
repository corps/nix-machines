{ pkgs ? import <nixpkgs> { 
  overlays = [
  (import (builtins.fetchTarball {
      url = "https://github.com/m15a/nixpkgs-vim-extra-plugins/archive/main.tar.gz";
    })).overlays.default
  ];
}
, buildVimPluginFrom2Nix ? pkgs.vimUtils.buildVimPluginFrom2Nix
, fetchurl ? pkgs.fetchurl
}:
# let plugins = pkgs.callPackage ./plugins.nix {}; in
# https://github.com/m15a/nixpkgs-vim-extra-plugins/blob/main/pkgs/vim-plugins.nix
{
  customRC = ''${builtins.readFile ./vimrc}'';

  packages.neovimPlugins = with pkgs.vimPlugins; with pkgs.vimExtraPlugins; {
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

      cmp-vsnip
      vim-vsnip

      trouble-nvim

      nvim-transparent
      # nnn-nvim
      (
        buildVimPluginFrom2Nix {
          pname = "nnn-nvim";
          version = "2022-08-23";
          src = fetchurl {
            url = "https://github.com/luukvbaal/nnn.nvim/archive/d2299030876eef9297ee8bfe6304872bb36b2689.tar.gz";
            sha256 = "XcnpkRfpoWoT3MbfMtBuw76tG+SCQhFFcdBRCOnRStc=";
          };
        }
      )
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
