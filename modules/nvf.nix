{ pkgs, inputs }:

{
  environment.systemPackages = [
    (inputs.nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = [
        {
          config.vim = {
            # Enable custom theming options
            theme.enable = true;
            # Enable Treesitter
            treesitter.enable = true;
          };
        }
      ];
    }).neovim
  ];
}
