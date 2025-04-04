{
  pkgs ? import <nixpkgs> { },
}:

with pkgs;
let
  vineSrc = fetchFromGitHub {
    owner = "VineLang";
    repo = "vine";
    rev = "b768a4d9e95dd48f4c2af5e003d482db199f922b";
    hash = "sha256-wrAEQ/KoY1qkhRVBPlRYNZAlLOlCEAvkIND5V0G83LQ=";
  };
  rustPlatform = makeRustPlatform {
    cargo = rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
    rustc = rust-bin.selectLatestNightlyWith (toolchain: toolchain.default);
  };
in

rustPlatform.buildRustPackage rec {
  pname = "vine";
  version = "0.1";
  src = lib.cleanSource vineSrc;
  CFG_RELEASE_CHANNEL = "nightly";
  cargoLock = {
    lockFile = "${src}/Cargo.lock";
    outputHashes = {
      "class-0.1.0" = "sha256-ye8DqeDRXsNpTWpGGlvWxSSc1AiXOLud99dHpB/VhZg=";
    };
  };
}
