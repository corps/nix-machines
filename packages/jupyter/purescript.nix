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
  rev = "2f05cb6c7e4a5530e7d08bbe7158c92e8d94bf78";
  sha256 = "0hl6mfgmxinjf6gki5dcdamia6wycv10l6gxdqaszl9v68rrh4n4";
};

npmInstalls = lib.concatStringsSep "\n" (builtins.map (p: "npm install ${p} --save") npmPackages);

bowerInstalls = lib.concatStringsSep "\n" (builtins.map (p: "bower install ${p} --save")
bowerPackages);

path = "/lib/node_module/purescript-kernel";

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
