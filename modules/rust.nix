{
  config,
  lib,
  pkgs,
  ...
}:

with lib;

{
  imports = [
    ./development.nix
  ];

  config = mkIf config.environment.development.enable {
    programs.bash.interactiveShellInit = ''
      source <(rustup completions bash)
      source <(rustup completions bash cargo)
    '';

    environment = {
      systemPackages = with pkgs; [
        rustup
      ];
    };
  };
}
