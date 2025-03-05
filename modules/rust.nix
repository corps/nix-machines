{
  lib,
  pkgs,
  ...
}:

with lib;

{
  config = {
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
