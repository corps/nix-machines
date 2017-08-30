{ pkgs, fetchFromGitHub }:
let buildVimPlugin = pkgs.vimUtils.buildVimPluginFrom2Nix;
in {
  denite-nvim = buildVimPlugin {
    name = "denite-nvim";
    src = fetchFromGitHub {
      owner = "Shougo";
      repo = "denite.nvim";
      rev = "a9bc1786370ea5b0a1269735c94feba3da52d475";
      sha256 = "1b671279vhd14pnq8vyayfc6j2flwf0jiv2wn2s9yshrnbmc46zf";
    };
  };
  deoplete-nvim = buildVimPlugin {
    name = "deoplete-nvim";
    src = fetchFromGitHub {
      owner = "Shougo";
      repo = "deoplete.nvim";
      rev = "ac4e8b56115f1bdcda5401ea7eeb1b5a3046ebe3";
      sha256 = "03r8l6fvz953iwc57cjr2pg61bh8i25rgs2hj0hm713mxkjxqpys";
    };
  };
  neovim-fuzzy = buildVimPlugin {
    name = "neovim-fuzzy";
    src = fetchFromGitHub {
      owner = "cloudhead";
      repo = "neovim-fuzzy";
      rev = "5d563596bb7be161797d79425bcadb0fb30308ce";
      sha256 = "0b9z6xb62ayhkb8f2k3c2d0rklm4qb2s8pnqz5lbdkccrnclhah2";
    };
  };
  editorconfig-vim = buildVimPlugin {
    name = "editorconfig-vim";
    src = fetchFromGitHub {
      owner = "editorconfig";
      repo = "editorconfig-vim";
      rev = "14376e0e7f8118af7297daa8d4f5f261ca4efacb";
      sha256 = "10ac0p06rb02078rr3idz5d7fn92w6721jl5l92bkjcx68di9hh4";
    };
  };
  supertab = buildVimPlugin {
    name = "supertab";
    src = fetchFromGitHub {
      owner = "ervandew";
      repo = "supertab";
      rev = "22aac5c2cb6a8ebe906bf1495eb727717390e62e";
      sha256 = "1m70rx9ba2aqydfr9yxsrff61qyzmnda24qkgn666ypnsai7cfbn";
    };
  };
  vim-go = buildVimPlugin {
    name = "vim-go";
    src = fetchFromGitHub {
      owner = "fatih";
      repo = "vim-go";
      rev = "52c5b1f74dade7ef21b34675751cd4a7b3ee2d03";
      sha256 = "0piw1lqhkqds46nin8clbdhhwh2wxd0y1hbayqc45pi3zqyyikdb";
    };
  };
  incsearch-fuzzy-vim = buildVimPlugin {
    name = "incsearch-fuzzy-vim";
    src = fetchFromGitHub {
      owner = "haya14busa";
      repo = "incsearch-fuzzy.vim";
      rev = "b08fa8fbfd633e2f756fde42bfb5251d655f5403";
      sha256 = "15djvhm6ya9yj269c19dizhk8x9arl61s2gnjxqfp0j55yr30k60";
    };
  };
  incsearch-vim = buildVimPlugin {
    name = "incsearch-vim";
    src = fetchFromGitHub {
      owner = "haya14busa";
      repo = "incsearch.vim";
      rev = "ceff51093e5dac1cf566b6748de7108bc5235b33";
      sha256 = "0s5h39gndd6fhc770mxaaskrzkb0dnnal613xzzsvmc2np5sa0j3";
    };
  };
  vim-fetch = buildVimPlugin {
    name = "vim-fetch";
    src = fetchFromGitHub {
      owner = "kopischke";
      repo = "vim-fetch";
      rev = "ce1bfadb9120c92794534d995cd44b0ec6f6fb3e";
      sha256 = "00zi1iav2p4pgx21jrknphkbvslnx3r8bsnkg7qq42nw8bhl7d95";
    };
  };
  nvim-typescript = buildVimPlugin {
    name = "nvim-typescript";
    src = fetchFromGitHub {
      owner = "mhartington";
      repo = "nvim-typescript";
      rev = "2aac081aabbe7d258c69cd56c323478fc3ca80d7";
      sha256 = "0y8p2v7210xb2lcvdba5iiav83x6g6sib3psmbk8ayq4p4dznjv6";
    };
  };
  vim-grepper = buildVimPlugin {
    name = "vim-grepper";
    src = fetchFromGitHub {
      owner = "mhinz";
      repo = "vim-grepper";
      rev = "c12ea4d2234d561e0588061e710ef60faf9b5795";
      sha256 = "10qwaywcffspbr2l9sx5010s6szcixwylicf4lncwg60v7n6ikhz";
    };
  };
  sourcebeautify-vim = buildVimPlugin {
    name = "sourcebeautify-vim";
    src = fetchFromGitHub {
      owner = "michalliu";
      repo = "sourcebeautify.vim";
      rev = "6c5867a8322b04a3d2bf72c26ec1c5bc2fa8f676";
      sha256 = "01zcfmc7kp2drarark6m87h4il5qcqdjj16pv22sm3mvc3pshcpj";
    };
  };
  neomake = buildVimPlugin {
    name = "neomake";
    src = fetchFromGitHub {
      owner = "neomake";
      repo = "neomake";
      rev = "4b1b505e74792cf38441ac22e612b5d310ffa657";
      sha256 = "0s0jxv7fh8jz7j9yqsck7rf87rrbrmnlm32h10qa3rp5v25laph2";
    };
  };
  vim-javascript = buildVimPlugin {
    name = "vim-javascript";
    src = fetchFromGitHub {
      owner = "pangloss";
      repo = "vim-javascript";
      rev = "ee376ba5c828dc5f5266f80636c2ad212ac4806d";
      sha256 = "0jg472pz1k96zjrmmjgzffj0fh5zkwfi5pwxs0wcwna007r6n5r0";
    };
  };
  vim-srcery = buildVimPlugin {
    name = "vim-srcery";
    src = fetchFromGitHub {
      owner = "roosta";
      repo = "vim-srcery";
      rev = "20bdadb8876397ea6e8e5a8a81fc4dbcec560a77";
      sha256 = "12gjav4i0ap4mjab415y0rlszj687plb62vcd5zvdlzds1jv6hfa";
    };
  };
  neoformat = buildVimPlugin {
    name = "neoformat";
    src = fetchFromGitHub {
      owner = "sbdchd";
      repo = "neoformat";
      rev = "6810786688a95752f9e8ff9b39cb62f79a873681";
      sha256 = "1b4bg8fpkvmjbzghal6aqig8api164npb3z603r3svwar2sm9jl7";
    };
  };
  vim-polyglot = buildVimPlugin {
    name = "vim-polyglot";
    src = fetchFromGitHub {
      owner = "sheerun";
      repo = "vim-polyglot";
      rev = "9bfde7574aa89a91b80ed9c993fc000cfc11aae7";
      sha256 = "15bjh24kar5ya35v1ws1s2z9k4lixd9x3cyi84ahm6z9smi3q1fj";
    };
  };
  vim-eunuch = buildVimPlugin {
    name = "vim-eunuch";
    src = fetchFromGitHub {
      owner = "tpope";
      repo = "vim-eunuch";
      rev = "b536b887072ff3cc382842ce9f675ec222302f4f";
      sha256 = "0vp037kb12mawy186cm384m5hl0p051rihhm1jr2qck0vwaps58p";
    };
  };
  vim-fugitive = buildVimPlugin {
    name = "vim-fugitive";
    src = fetchFromGitHub {
      owner = "tpope";
      repo = "vim-fugitive";
      rev = "913fff1cea3aa1a08a360a494fa05555e59147f5";
      sha256 = "1qxzxk5szm25r7wi39n5s91fjnjgz5xib67risjcwhk6jdv0vzyd";
    };
  };
  vim-rails = buildVimPlugin {
    name = "vim-rails";
    src = fetchFromGitHub {
      owner = "tpope";
      repo = "vim-rails";
      rev = "7206033fc2d7d53a531502ecd5a044ecdacc0354";
      sha256 = "1r92p3j9kmzffxsaqsbnsdy0wnwv4pjzgckgp4sgd5l6c7ikxq10";
    };
  };
  vim-surround = buildVimPlugin {
    name = "vim-surround";
    src = fetchFromGitHub {
      owner = "tpope";
      repo = "vim-surround";
      rev = "e49d6c2459e0f5569ff2d533b4df995dd7f98313";
      sha256 = "1v0q2f1n8ngbja3wpjvqp2jh89pb5ij731qmm18k41nhgz6hhm46";
    };
  };
  vim-airline = buildVimPlugin {
    name = "vim-airline";
    src = fetchFromGitHub {
      owner = "vim-airline";
      repo = "vim-airline";
      rev = "f0a508b1216215c01640f06d23889934097924ee";
      sha256 = "1154ic3icji1xd4szygnvzy0g5y7c0y3llxzmn4azx5msjc6766y";
    };
  };
  vim-airline-themes = buildVimPlugin {
    name = "vim-airline-themes";
    src = fetchFromGitHub {
      owner = "vim-airline";
      repo = "vim-airline-themes";
      rev = "08c76e4cd0cdaa12c476ed03b920912173e31339";
      sha256 = "0l3agy3vzldm0v4vwlrvj0q60bzhg813ip5dah9cplw2jvkhqr4b";
    };
  };
  css-pretty = buildVimPlugin {
    name = "css-pretty";
    src = fetchFromGitHub {
      owner = "vim-scripts";
      repo = "Css-Pretty";
      rev = "0c90d27d38b7cfa2ba636986ab0d0d63865bd633";
      sha256 = "0i08bnsyhar1ynzvkbb79z5fxg22ifcyjnp4f8sbkx3p4lw4hhvq";
    };
  };
  vimwiki = buildVimPlugin {
    name = "vimwiki";
    src = fetchFromGitHub {
      owner = "vimwiki";
      repo = "vimwiki";
      rev = "4831384ab9f1c40c9e433857d958c4d9a7beb8ec";
      sha256 = "1wjbsd37h5fxkkia90h708mmqisdj0kxzm9k97jm2zq36zngmd86";
    };
  };
}
