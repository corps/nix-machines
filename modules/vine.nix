{
  pkgs,
  inputs,
  ...
}:

{
  config = {
    programs.bash.interactiveShellInit = '''';
    nixpkgs.overlays = [ inputs.rust-overlay.overlays.default ];

    environment = {
      systemPackages = [
        (pkgs.callPackage ../vine.nix { inherit pkgs; })
      ];
    };
  };
}
