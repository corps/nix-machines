{
  pkgs,
  ...
}:

{
  config = {
    environment.systemPackages = with pkgs; [ elan ];

    programs.bash.interactiveShellInit = ''
      source <(elan completions bash)
    '';
  };
}
