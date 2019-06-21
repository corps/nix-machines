{ config, lib, pkgs, ... }:

{
  imports = [
    ../shared
  ];

  environment.systemPackages = with pkgs; [
    mitmproxy
  ];

  nix.nixPath = [ # Include default path <wsl-config>.
    "up=${toString ../../nix-up}"
    "up-config=$HOME/.nixpkgs/up-configuration.nix"
    ("nixpkgs=" + (toString ../../packages/pinned/nixos-19.03))
    "$HOME/.nix-defexpr/channels"
  ];

  nixpkgs.config.vim.ftNix = false;
  nix.package = pkgs.nix;
}
