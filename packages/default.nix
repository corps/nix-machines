self: super:

let callPackage = super.newScope self; in rec {
  ngrok = callPackage ./ngrok {};
  bring-to-front = callPackage ./bring-to-front.nix {};
  # my_neovim = callPackage ./vim {};
  # my_neovim = callPackage ./lvim {};
  my_neovim = self.neovim-unwrapped;
  fetch_from_github = callPackage ./fetch-from-github.nix {};
  upgrade-packages = callPackage ./upgrade-packages {};
  fetch_from_pypi = callPackage ./fetch-from-pypi.nix {};
  activate-window = callPackage ./activate-window.nix {};
  bring-to-front-desktop = callPackage ./bring-to-front-desktop.nix {};
  add-bin-to-path = callPackage ./add-bin-to-path.nix {};
}
