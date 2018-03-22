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

src = fetchFromGitHub {
  owner = "corps";
  repo = "purescript-kernel";
  rev = "b704fe7250440ee345b3327f116165097ae36665";
  sha256 = "17zx7lj84iwv8l856c9kxycj16g1rhq79fna31zz79i5n6hgj98n";
};

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
