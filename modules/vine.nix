{
  inputs,
  pkgs,
  ...
}:

{
  config = {
    programs.bash.interactiveShellInit = '''';

    environment = {
      systemPackages = [
        inputs.vine.packages.${pkgs.system}.default
        inputs.py-ivm.packages.${pkgs.system}.default
      ];
    };
  };
}
