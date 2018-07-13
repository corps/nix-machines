{ stdenv, writeScript, nix, pkgs }:

let nixPath = stdenv.lib.concatStringsSep ":" [
  "wsl-config=${toString ./configuration.nix}"
  "wsl=${toString ../..}"
  "nixpkgs=${toString pkgs.path}"
  "$NIX_PATH"
];

in

stdenv.mkDerivation {
  name = "wsl-installer";
  preferLocalBuild = true;

  unpackPhase = ":";
  installPhase = ''
    mkdir -p $out/bin
    echo "$shellHook" > $out/bin/wsl-installer
    chmod +x $out/bin/wsl-installer
  '';

  shellHook = ''
    set -e

    export nix=${nix}
    config=$($nix/bin/nix-instantiate --eval -E '<wsl-config>' 2> /dev/null || echo "$HOME/.nixpkgs/wsl-configuration.nix")
    if ! test -f "$config"; then
      echo "copying example configuration.nix" >&2;
      mkdir -p "$HOME/.nixpkgs"
      cp "${toString ../../configuration.nix.template}" "$config"
      chmod u+w "$config"
    fi

    export WINHOME=$(wslpath $(cmd.exe /c 'echo %USERPROFILE%' | tr -d '\r\n'))
    startup="$WINHOME/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup"

    export NIX_PATH=${nixPath}
    system=$($nix/bin/nix-build '<wsl>' -I "user-wsl-config=$config" -A system --no-out-link)
    export PATH=$system/sw/bin:$PATH


    wsl-rebuild switch -I "user-wsl-config=$config"

    cp "${toString ./ActivateSystem.vbs}" "$startup/ActivateSystem.vbs"
    exit
  '';
}
