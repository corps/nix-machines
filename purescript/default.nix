{ inputs ? {}, easy-ps ? inputs.easy-purescript-nix.packages.${pkgs.system}; }:

rec {
  purs = easy-ps.purs-0_15_15;
  spago = easy-ps.spago;
  purs-lsp = easy-ps.purescript-language-server;
  purs-tidy = easy-ps.purs-tidy;
  all = [purs, spago, purs-lsp, purs-tidy]
}
