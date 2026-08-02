{
  pkgs,
  inputs,
  ...
}: {
  environment.systemPackages = [
    (inputs.nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = [
        {
          config.vim = {
            opts.expandtab = true;
            opts.tabstop = 2;
            opts.shiftwidth = 2;
            opts.softtabstop = 2;

            lsp = {
              enable = true;
              formatOnSave = true;

              # How to codeactions?
              lightbulb.enable = true;
            };

            theme.enable = true;
            treesitter.enable = true;
            treesitter.context.enable = true;

            tabline = {
              nvimBufferline.enable = true;
            };

            filetree = {
              neo-tree = {
                enable = true;
              };
            };

            binds = {
              whichKey.enable = true;
              whichKey.register = {
                "<leader>l" = "Lsp Actions";
              };
              cheatsheet.enable = true;
            };

            languages = {
              enableFormat = true;
              enableTreesitter = true;
              enableExtraDiagnostics = true;

              python = {
                enable = true;
              };

              nix = {
                enable = true;
              };

              env = {
                enable = true;
              };

              docker = {
                enable = true;
              };

              typescript = {
                enable = true;
              };

              cmake = {
                enable = true;
              };
            };
          };
        }
      ];
    }).neovim
  ];
}
