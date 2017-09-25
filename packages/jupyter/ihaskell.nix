{ fetchFromGitHub, jupyter }:

let

pkgs = import (fetchFromGitHub {
  owner  = "NixOS";
  repo   = "nixpkgs";
  rev    = "ea1d5e9c7a054eb4ec2660e144133bdbb58a0ae0";
  sha256 = "0x95sqfbgdhmnpx3hfgvy7whjgq0d1zlmi8853jhpl7c26bfw07h";
}) {};

src = fetchFromGitHub {
  owner = "gibiansky";
  repo = "IHaskell";
  rev = "d35628d10a464ee5d4778b787cd9ab1794fcaee8";
  sha256 = "1z24szyag7xmvn7dvhlf33p4b8x95br5r3yvhfsdlz4nrgxppk91";
};

packages = self: with self; [
    lens
    SHA
    attoparsec
    bytestring
    directory
    filepath
    utf8-string
    byteable
];

systemPackages = pkgs: with pkgs; [
  coreutils
  findutils
  git
  qpdf
];

# import pinnedNix {};

displays = self: builtins.listToAttrs (
  map
    (display: { name = display; value = self.callCabal2nix display "${src}/ihaskell-display/${display}" {}; })
    [
      "ihaskell-aeson"
      "ihaskell-blaze"
      "ihaskell-charts"
      "ihaskell-diagrams"
      "ihaskell-gnuplot"
      "ihaskell-hatex"
      "ihaskell-juicypixels"
      "ihaskell-magic"
      "ihaskell-plot"
      "ihaskell-rlangqq"
      "ihaskell-static-canvas"
      "ihaskell-widgets"
    ]);

dontCheck = pkgs.haskell.lib.dontCheck;

haskellPackages = pkgs.haskellPackages.override {
  overrides = self: super: {
    ihaskell = pkgs.haskell.lib.overrideCabal (self.callCabal2nix "ihaskell" src {}) (_drv: {
      doCheck = false;
      postPatch = ''
        substituteInPlace ./src/IHaskell/Eval/Evaluate.hs --replace \
          'hscTarget = objTarget flags' \
          'hscTarget = HscInterpreted'
      '';
    });
    ghc-parser     = self.callCabal2nix "ghc-parser"     "${src}/ghc-parser"     {};
    ipython-kernel = self.callCabal2nix "ipython-kernel" "${src}/ipython-kernel" {};
  } // displays self;
};

ihaskell = haskellPackages.ihaskell;

ihaskellEnv = haskellPackages.ghcWithPackages (self: with self; [
  ihaskell
  ihaskell-aeson
  ihaskell-blaze
  ihaskell-charts
  ihaskell-diagrams
  ihaskell-gnuplot
  ihaskell-hatex
  ihaskell-juicypixels
  ihaskell-magic
  ihaskell-plot
  # ihaskell-rlangqq
  ihaskell-static-canvas
  # ihaskell-widgets
] ++ packages self);

in

pkgs.writeScriptBin "ihaskell" ''
  #! ${pkgs.bash}/bin/bash -e
  export GHC_PACKAGE_PATH="$(echo ${ihaskellEnv}/lib/*/package.conf.d| tr ' ' ':'):$GHC_PACKAGE_PATH"
  export PATH="${pkgs.stdenv.lib.makeBinPath ([ ihaskell ihaskellEnv jupyter ] ++ systemPackages pkgs)}"
  exec ihaskell kernel $@ --ghclib $(${ihaskellEnv}/bin/ghc --print-libdir)
''
