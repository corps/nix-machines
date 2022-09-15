self: super:

let callPackage = super.newScope self; in rec {
  ngrok = callPackage ./ngrok {};
  bring-to-front = callPackage ./bring-to-front.nix {};
  my_neovim = callPackage ./vim {
    pkgs = import <nixpkgs> { 
      overlays = [
        (import (builtins.fetchTarball {
            url = "https://github.com/m15a/nixpkgs-vim-extra-plugins/archive/main.tar.gz";
          })).overlays.default
      ];
    };
  };
  # my_neovim = callPackage ./lvim {};
  # my_neovim = self.neovim-unwrapped;
  # spleeter = callPackage ./spleeter.nix {};
  fetch_from_github = callPackage ./fetch-from-github.nix {};
  upgrade-packages = callPackage ./upgrade-packages {};
  fetch_from_pypi = callPackage ./fetch-from-pypi.nix {};
  activate-window = callPackage ./activate-window.nix {};
  bring-to-front-desktop = callPackage ./bring-to-front-desktop.nix {};
  add-bin-to-path = callPackage ./add-bin-to-path.nix {};
  runc = callPackage ./runc.nix {};
}
