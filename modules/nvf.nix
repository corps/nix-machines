{
  pkgs,
  inputs,
  ...
}: let
  keymaps = [
    {
      key = "<d-c>";
      mode = "n";
      silent = true;
      action = "\"*y :let @+=@*<CR>";
    }
    {
      key = "<d-v>";
      mode = "n";
      silent = true;
      action = "+p";
    }
    {
      key = "<d-v>";
      mode = "i";
      silent = true;
      action = "<C-R>+";
    }
    {
      key = "<d-{>";
      mode = "n";
      silent = true;
      action = ":BufferLineCyclePrev<CR>";
    }
    {
      key = "<d-}>";
      mode = "n";
      silent = true;
      action = ":BufferLineCycleNext<CR>";
    }
    {
      key = "<d-w>";
      mode = "n";
      silent = true;
      action = ":bd<CR>";
    }

    {
      key = "<leader>{";
      mode = "n";
      silent = true;
      action = ":BufferLineCyclePrev<CR>";
    }
    {
      key = "<leader>}";
      mode = "n";
      silent = true;
      action = ":BufferLineCycleNext<CR>";
    }
    {
      key = "<leader>w";
      mode = "n";
      silent = true;
      action = ":bd<CR>";
    }
    {
      key = "<d-/>";
      mode = "v";
      silent = true;
      action = "gc";
    }
    {
      key = "<d-/>";
      mode = "n";
      silent = true;
      action = "gcc";
    }
    {
      key = "<d-[>";
      mode = "n";
      silent = true;
      action = "<C-o>";
    }
    {
      key = "<d-]>";
      mode = "n";
      silent = true;
      action = "<C-i>";
    }
    {
      key = "<d-b>";
      mode = "n";
      silent = true;
      action = "<leader>lgd";
    }
  ];
in {
  environment.systemPackages = [
    (inputs.nvf.lib.neovimConfiguration {
      inherit pkgs;
      modules = [
        {
          config.vim = {
            inherit keymaps;

            opts = {
              expandtab = true;
              tabstop = 2;
              shiftwidth = 2;
              softtabstop = 2;
            };

            lsp = {
              enable = true;
              formatOnSave = true;

              # How to codeactions?
              lightbulb.enable = true;
              trouble.enable = true;
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

            autocomplete.nvim-cmp = {
              enable = true;
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
