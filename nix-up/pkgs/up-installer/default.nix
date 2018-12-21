{ stdenv, writeScript, nix, pkgs }:

let nixPath = stdenv.lib.concatStringsSep ":" [
  "up-config=${toString ./configuration.nix}"
  "up=${toString ../..}"
  "nixpkgs=${toString pkgs.path}"
  "$NIX_PATH"
];

in

stdenv.mkDerivation {
  name = "up-installer";
  preferLocalBuild = true;

  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/bin
    echo "$shellHook" > $out/bin/up-installer
    chmod +x $out/bin/up-installer
  '';

  shellHook = ''
    set -e

    export nix=${nix}
    config=$($nix/bin/nix-instantiate --eval -E '<up-config>' 2> /dev/null || echo "$HOME/.nixpkgs/up-configuration.nix")
    if ! test -f "$config"; then
      echo "copying example configuration.nix" >&2;
      mkdir -p "$HOME/.nixpkgs"
      cp "${toString ../../configuration.nix.template}" "$config"
      chmod u+w "$config"
    fi

    export NIX_PATH=${nixPath}
    system=$($nix/bin/nix-build '<up>' -I "user-up-config=$config" -A system --no-out-link)
    export PATH=$system/sw/bin:$PATH

    up-rebuild switch -I "user-up-config=$config"

    exit
  '';
}
