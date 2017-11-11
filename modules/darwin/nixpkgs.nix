{
  nix.nixPath = [
    "darwin-config=$HOME/.nixpkgs/darwin-configuration.nix"
    "/nix/var/nix/profiles/per-user/root/channels"
    "$HOME/.nix-defexpr/channels"
    "nixpkgs-overlays=$HOME/Development/nix-machines/overlays"
  ];

  nixpkgs.config.allowUnfree = true;
}
