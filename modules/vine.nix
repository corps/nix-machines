{
  inputs,
  ...
}:

{
  config = {
    programs.bash.interactiveShellInit = '''';

    environment = {
      systemPackages = [
        inputs.vine
      ];
    };
  };
}
