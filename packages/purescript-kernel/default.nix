{
lib,
nix,
stdenv,
callPackage,
git,
fetchFromGitHub,
npmPackages ? [],
bowerPackages ? [],
nodejs,
nodePackages,
}:

let

src = callPackage ./package.nix {};

npmInstalls = lib.concatStringsSep "\n" (builtins.map (p: "npm install ${p} --save") npmPackages);

bowerInstalls = lib.concatStringsSep "\n" (builtins.map (p: "bower install ${p} --save")
bowerPackages);

path = "/lib/node_modules/purescript-kernel";

customized = stdenv.mkDerivation {
  inherit src;

  name = "customized-purescript-env";

  phases = [ "unpackPhase" "buildPhase" "installPhase" ];

  buildInputs = [
    nodejs nodePackages.bower git
    nodePackages.node2nix
    nodePackages.bower2nix
    nix
  ];

  buildPhase = ''
    export HOME=$(mktemp -d)
    ${npmInstalls}
    ${bowerInstalls}
    bower2nix bower.json bower-package.nix
    node2nix -6 -i package.json --composition npm-package.nix --supplement-input global-npm-packages.json
  '';

  installPhase = ''
    cp -r . $out
  '';
};

in

(callPackage customized {}) + path
