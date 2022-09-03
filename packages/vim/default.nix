{ pkgs, neovim, ... }:

neovim.override {
  vimAlias = true;
  configure = (import ./configuration.nix { inherit pkgs; });
}


