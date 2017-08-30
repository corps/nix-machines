{ pkgs, neovim, ... }:

neovim.override {
  vimAlias = true;
  extraPython3Packages = [
    # (latestNixpkgs.callPackage ./pyuv.nix {
    #   buildPythonPackage = latestNixpkgs.python3Packages.buildPythonPackage;
    # })
    # latestNixpkgs.python3Packages.enum34
  ];
  configure = (import ./configuration.nix { inherit pkgs; });
}
