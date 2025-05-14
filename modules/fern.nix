{
  pkgs ? import <nixpkgs>,
  lib ? pkgs.lib,
  fetchFromGitHub ? pkgs.fetchFromGitHub,
  pnpm_9 ? pkgs.pnpm_9,
  nodejs ? pkgs.nodejs,
  writeShellScriptBin ? pkgs.writeShellScriptBin,
}:

let
  pnpm = pnpm_9;
  version = "0.61.3";
  src = fetchFromGitHub {
    owner = "fern-api";
    repo = "fern";
    tag = "${version}";
    hash = "sha256-S2EXWkGzYdkHMDNDzB5mMVjFFR22kgG2bphL2okviY4=";
  };
in
pkgs.stdenv.mkDerivation (finalAttrs: {
  pname = "fern-api";
  inherit version src;

  pnpmDeps = pnpm.fetchDeps {
    inherit (finalAttrs)
      pname
      version
      src
      ;
    hash = "sha256-52diJWEXz+wDU6aATMdBdrrOtVUq6RqhpBvB1cCv2Cg=";
    prePnpmInstall = ''
      pnpm config set dedupe-peer-dependants false
    '';
  };

  nativeBuildInputs = [
    nodejs
    pkgs.jq
    pnpm.configHook
  ];

  buildPhase = ''
    runHook preBuild
    pnpm compile
    npm run fern:build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/fern
    deps_json=$(pnpm list --filter ./packages/cli/cli --prod --depth Infinity --json)
    deps=$(jq -r '[.. | strings | select(startswith("link:../")) | sub("^link:../"; "")] | unique[]' <<< "$deps_json")

    # Remove unnecessary external dependencies
    find . -name node_modules -type d -prune -exec rm -rf {} +
    pnpm install --offline --ignore-scripts --frozen-lockfile --prod
    cp -r node_modules $out/lib/fern

    # Only install cli and its workspace dependencies
    for package in cli $deps; do
    filename=$(npm pack --json ./packages/$package | jq -r '.[].filename')
    mkdir -p $out/lib/fern/packages/$package
    [ -d "packages/$package/node_modules" ] && \
    cp -r packages/$package/node_modules $out/lib/fern/packages/$package
    tar xf $filename --strip-components=1 -C $out/lib/fern/packages/$package
    done

    # Remove dangling symlinks to packages we didn't copy to $out
    find $out/lib/fern/node_modules/.pnpm/node_modules -type l -exec test ! -e {} \; -delete

    makeWrapper "${lib.getExe nodejs}" "$out/bin/fern" --add-flags "$out/lib/fern/packages/cli/cli/build.prod.cjs"

    # mkdir -p $out
    # cp -r * $out/
    # pnpm --offline --frozen-lockfile --ignore-script --filter @fern-api/cli deploy --prod $out/lib/
    # cp -r packages/cli/cli/dist/prod/cli.cjs $out/share/
    # makeWrapper ${lib.getExe nodejs} $out/bin/fern --inherit-argv0 --add-flags $out/lib/fern-api/out/cli.js

    runHook postInstall
  '';

  doInstallCheck = true;
})

# writeShellScriptBin "fern" ''
#   if ! [ -e ~/.fern ]; then
#     (
#     cd ${lib.getDev compiled}
#     ${pnpm}/bin/pnpm --frozen-lockfile --ignore-script --filter @fern-api/cli deploy  --prod ~/.fern
#     )
#   fi
#
#   echo hi
# ''
