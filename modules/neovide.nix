{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  options = {
    programs.neovide.enable = mkOption {
      default = false;
      type = types.bool;
    };
  };

  config = let
    # TEMPORARY: nixpkgs master's neovide 0.17.1 update (PR #583110)
    # copy-pasted the skia m156.5 hash into src and cargoHash, breaking the
    # build with fixed-output hash mismatches. Patch the hashes here until
    # nixpkgs catches up, then delete this let binding.
    neovide =
      if pkgs.neovide.version or null == "0.17.1" then
        pkgs.neovide.overrideAttrs (old: {
          src = pkgs.fetchFromGitHub {
            owner = "neovide";
            repo = "neovide";
            tag = "0.17.1";
            hash = "sha256-trl/YctM/E9vIXeJfwBEZLfNK7LS5fEaWthTbeg7Ba0=";
          };
          cargoHash = "sha256-WS44afUizU6qhXQY77TayNRvlUoS6GrBZ/uaXk+gjU0=";
        })
      else
        pkgs.neovide;
  in {
    environment.systemPackages = (if config.programs.neovide.enable then [ neovide ] else [ ]);
  };
}
