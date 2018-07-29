{ pkgs, fetchFromGitHub }:
let 
buildVimPlugin = pkgs.vimUtils.buildVimPluginFrom2Nix;
pluginSrc = src: (import src) { inherit
fetchFromGitHub; };
in {
  purescript-vim = buildVimPlugin {
    name = "purescript-vim";
    src = pluginSrc ./plugins/purescript-contrib.purescript-vim.nix;
  };

  psc-ide-vim = buildVimPlugin {
    name = "psc-ide-vim";
    src = pluginSrc ./plugins/FrigoEU.psc-ide-vim.nix;
  };

  indent-guide = buildVimPlugin {
    name = "indent-guide";
    src = pluginSrc ./plugins/nathanaelkane.vim-indent-guides.nix;
  };

  vim-commentary = buildVimPlugin {
    name = "vim-commentary";
    src = pluginSrc ./plugins/tpope.vim-commentary.nix;
  };

  vim-repeat = buildVimPlugin {
    name = "vim-repeat";
    src = pluginSrc ./plugins/tpope.vim-repeat.nix;
  };

  neoterm = buildVimPlugin {
    name = "neoterm";
    src = pluginSrc ./plugins/kassio.neoterm.nix;
  };

  denite-nvim = buildVimPlugin {
    name = "denite-nvim";
    src = pluginSrc ./plugins/Shougo.denite.nvim.nix;
  };

  deoplete-nvim = buildVimPlugin {
    name = "deoplete-nvim";
    src = pluginSrc ./plugins/Shougo.deoplete.nvim.nix;
  };

  neovim-fuzzy = buildVimPlugin {
    name = "neovim-fuzzy";
    src = pluginSrc ./plugins/cloudhead.neovim-fuzzy.nix;
  };

  editorconfig-vim = buildVimPlugin {
    name = "editorconfig-vim";
    src = pluginSrc ./plugins/editorconfig.editorconfig-vim.nix;
  };

  supertab = buildVimPlugin {
    name = "supertab";
    src = pluginSrc ./plugins/ervandew.supertab.nix;
  };

  vim-go = buildVimPlugin {
    name = "vim-go";
    src = pluginSrc ./plugins/fatih.vim-go.nix;
  };

  incsearch-fuzzy-vim = buildVimPlugin {
    name = "incsearch-fuzzy-vim";
    src = pluginSrc ./plugins/haya14busa.incsearch-fuzzy.vim.nix;
  };

  incsearch-vim = buildVimPlugin {
    name = "incsearch-vim";
    src = pluginSrc ./plugins/haya14busa.incsearch.vim.nix;
  };

  vim-buffergator = buildVimPlugin {
    name = "vim-buffergator";
    src = pluginSrc ./plugins/jeetsukumaran.vim-buffergator.nix;
  };

  vim-fetch = buildVimPlugin {
    name = "vim-fetch";
    src = pluginSrc ./plugins/kopischke.vim-fetch.nix;
  };

  nvim-typescript = buildVimPlugin {
    name = "nvim-typescript";
    src = pluginSrc ./plugins/mhartington.nvim-typescript.nix;
  };

  vim-grepper = buildVimPlugin {
    name = "vim-grepper";
    src = pluginSrc ./plugins/mhinz.vim-grepper.nix;
  };

  sourcebeautify-vim = buildVimPlugin {
    name = "sourcebeautify-vim";
    src = pluginSrc ./plugins/michalliu.sourcebeautify.vim.nix;
  };

  neomake = buildVimPlugin {
    name = "neomake";
    src = pluginSrc ./plugins/neomake.neomake.nix;
  };

  vim-javascript = buildVimPlugin {
    name = "vim-javascript";
    src = pluginSrc ./plugins/pangloss.vim-javascript.nix;
  };

  vim-srcery = buildVimPlugin {
    name = "vim-srcery";
    src = pluginSrc ./plugins/roosta.vim-srcery.nix;
  };

  neoformat = buildVimPlugin {
    name = "neoformat";
    src = pluginSrc ./plugins/sbdchd.neoformat.nix;
  };

  vim-polyglot = buildVimPlugin {
    name = "vim-polyglot";
    src = pluginSrc ./plugins/sheerun.vim-polyglot.nix;
  };

  vim-eunuch = buildVimPlugin {
    name = "vim-eunuch";
    src = pluginSrc ./plugins/tpope.vim-eunuch.nix;
  };

  vim-fugitive = buildVimPlugin {
    name = "vim-fugitive";
    src = pluginSrc ./plugins/tpope.vim-fugitive.nix;
  };

  vim-rails = buildVimPlugin {
    name = "vim-rails";
    src = pluginSrc ./plugins/tpope.vim-rails.nix;
  };

  vim-surround = buildVimPlugin {
    name = "vim-surround";
    src = pluginSrc ./plugins/tpope.vim-surround.nix;
  };

  vim-airline = buildVimPlugin {
    name = "vim-airline";
    src = pluginSrc ./plugins/vim-airline.vim-airline.nix;
  };

  vim-airline-themes = buildVimPlugin {
    name = "vim-airline-themes";
    src = pluginSrc ./plugins/vim-airline.vim-airline-themes.nix;
  };

  vim-ruby = buildVimPlugin {
    name = "vim-ruby";
    src = pluginSrc ./plugins/vim-ruby.vim-ruby.nix;
  };

  nerdtree = buildVimPlugin {
    name = "nerdtree";
    src = pluginSrc ./plugins/scrooloose.nerdtree.nix;
  };

  neovim-haskell = buildVimPlugin {
    name = "neovim-haskell";
    src = pluginSrc ./plugins/neovimhaskell.haskell-vim.nix;
  };

  vim-hindent = buildVimPlugin {
    name = "vim-hindent";
    src = pluginSrc ./plugins/alx741.vim-hindent.nix;
  };

  intero = buildVimPlugin {
    name = "intero";
    src = pluginSrc ./plugins/parsonsmatt.intero-neovim.nix;
  };
}
