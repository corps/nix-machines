{ pkgs, fetchFromGitHub }:
let buildVimPlugin = pkgs.vimUtils.buildVimPluginFrom2Nix;
in {
  purescript-vim = buildVimPlugin {
    name = "purescript-vim";
    src = fetchFromGitHub {
      owner = "purescript-contrib";
      repo = "purescript-vim";
      rev = "ece34d9782a075761f31854a33eccd932eb2cf57";
      sha256 = "0x6hpibmhgw5aqq25rcpvgz2a60jh7i8x23gigakmmrxv51cjcrj";
    };
  };

  psc-ide-vim = buildVimPlugin {
    name = "psc-ide-vim";
    src = fetchFromGitHub {
      owner = "FrigoEU";
      repo = "psc-ide-vim";
      rev = "737b9b65389884c8662a44d8a1bdd7465cd876b6";
      sha256 = "02nicrmlr43axk6cdf1y8vi4fzg0i1n8hamv0r0cd2mri4pxqxcr";
    };
  };

  indent-guide = buildVimPlugin {
    name = "indent-guide";
    src = fetchFromGitHub {
      owner = "nathanaelkane";
      repo = "vim-indent-guides";
      rev = "b40687195c01caf40f62d20093296590b48e3a75";
      sha256 = "17hc3bdb707lkg0kyac2czjjijdrzarnh6sr78s9rqpwrj3fj4i4";
    };
  };

  vim-commentary = buildVimPlugin {
    name = "vim-commentary";
    src = fetchFromGitHub {
      owner = "tpope";
      repo = "vim-commentary";
      rev = "89f43af18692d22ed999c3097e449f12fdd8b299";
      sha256 = "0nqm4s00c607r58fz29n67r2z5p5r9qayl5y1chy8bcrl59m17a2";
    };
  };

  vim-repeat = buildVimPlugin {
    name = "vim-repeat";
    src = fetchFromGitHub {
      owner = "tpope";
      repo = "vim-repeat";
      rev = "070ee903245999b2b79f7386631ffd29ce9b8e9f";
      sha256 = "1grsaaar2ng1049gc3r8wbbp5imp31z1lcg399vhh3k36y34q213";
    };
  };
  neoterm = buildVimPlugin {
    name = "neoterm";
    src = fetchFromGitHub {
      owner = "kassio";
      repo = "neoterm";
      rev = "701c9fb20ebac1c4d05410f8054fa004bc9ecba4";
      sha256 = "1wblgjn4c6ai7jb46xv3vx4dpwbmxrs5wr1824z2blnb17glas7p";
    };
  };
  denite-nvim = buildVimPlugin {
    name = "denite-nvim";
    src = fetchFromGitHub {
      owner = "Shougo";
      repo = "denite.nvim";
      rev = "b06f2cc7ebec79a5cb8a93965389099e96be8ec3";
      sha256 = "0bcj2ay4310fbfhv3jlk25b56d5zyshl8d8mylpysjcv12vj6yzs";
    };
  };
  deoplete-nvim = buildVimPlugin {
    name = "deoplete-nvim";
    # src = fetchFromGitHub {
    #   owner = "Shougo";
    #   repo = "deoplete.nvim";
    #   rev = "45f23f1586e7edc13c1fafca201a33112a4700f7";
    #   sha256 = "0nfzg1zhg2yxl91774wjqbgrnfk2xpz8pyl02gyqg7nyrnzz1fkh";
    # };
    src =fetchFromGitHub {
			owner = "Shougo";
			repo = "deoplete.nvim";
			rev = "01139867ab6c73c44099bcd355f383141c2e024d";
			sha256 = "15mpfk8l9g4h23mb7xbc675cp0gs39i89ckc9rsrmlqa995c00kf";
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
      rev = "aa526f0fb3ee6694063c9728e0d3e4974562011e";
      sha256 = "1ar3v84z5jma1mmr5fj8v88glm99j5pampjpw51nvgd5z037yb3w";
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
  vim-buffergator = buildVimPlugin {
    name = "vim-buffergator";
    src = fetchFromGitHub {
      owner = "jeetsukumaran";
      repo = "vim-buffergator";
      rev = "04dfbc0c78b0a29b340a99d0ff36ecf8f16e017d";
      sha256 = "0kra3rhxz3c8f7yhrwpdq9ccbyvl1sx4i9sg6x6ksgp334w1c6y2";
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
      rev = "b1d61b22d2459f1f62ab256f564b52d05626440a";
      sha256 = "0m499h7r85psp70y5rd79kxymfgzy9qs9fw5dy0yalihllvxpcwz";
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
    # src = fetchFromGitHub {
    #   owner = "neomake";
    #   repo = "neomake";
    #   rev = "f2bb4aeeb2a76b76c39d2a99372f64c0278274a8";
    #   sha256 = "1p2bc6i081i2i3vdpbm3w5cs6j1vr1j6qsdic95jn4q0b4g1njbc";
    # };
    src = fetchFromGitHub {
      owner = "neomake";
      repo = "neomake";
      rev = "2697d90e5db15489287d424076aa19673668530d";
      sha256 = "04zzvf9n7mzxffm7w1gxcwm1hab77a95341ljnc8x9q1n254garv";
    };
  };
  vim-javascript = buildVimPlugin {
    name = "vim-javascript";
    src = fetchFromGitHub {
      owner = "pangloss";
      repo = "vim-javascript";
      rev = "7198f32def8c9e5850e07a731faf673d045c5424";
      sha256 = "1gkrljzbgllgdn9dg9md577i13dlvbgn9nwh9xk69dg54phw4chz";
    };
  };
  vim-srcery = buildVimPlugin {
    name = "vim-srcery";
    src = fetchFromGitHub {
      owner = "roosta";
      repo = "vim-srcery";
      rev = "b08419ae6f5a949d9ecaef0cb9af93388acb1330";
      sha256 = "1jyfvrr38yn2qf0mlhi4y1gaw26vmij2363kxhfkf79w50dn4sz2";
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
      rev = "8f60d1d459362771cb68c0097565efdf52e62ec3";
      sha256 = "107mmdy1j5dnh3f00hwf68459fks2jiqv44awvg7qjdxp7si0r7h";
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
      rev = "ea461925619c3d812eb45a6b8c58eb85d951f43e";
      sha256 = "1gbbj76pqkhpamjxh7ag9srklp3hb7h559vnfqlw97l5f8594wi2";
    };
  };
  vim-airline-themes = buildVimPlugin {
    name = "vim-airline-themes";
    src = fetchFromGitHub {
      owner = "vim-airline";
      repo = "vim-airline-themes";
      rev = "af3292dbbb6d8abe35d0ad50bd86b6ac6219abb7";
      sha256 = "144vkwlc2f2y1b7xzgqvwaxv24l4sb13nqjqfn3jk851c3mpgb7y";
    };
  };
  vim-ruby = buildVimPlugin {
    name = "vim-ruby";
    src = fetchFromGitHub {
      owner = "vim-ruby";
      repo = "vim-ruby";
      rev = "074200ffa39b19baf9d9750d399d53d97f21ee07";
      sha256 = "1w2d12cl40nf73f3hcpqc4sqma8h1a557fy8kds2x143gq7s5vx6";
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
