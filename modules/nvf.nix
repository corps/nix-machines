{
  pkgs,
  lib,
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
      key = "<leader>e";
      mode = "n";
      silent = true;
      action = ":Neotree toggle<CR>";
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
    {
      key = "<leader>ff";
      mode = "n";
      silent = true;
      action = ":Telescope find_files<CR>";
    }
    {
      key = "<leader>fg";
      mode = "n";
      silent = true;
      action = ":Telescope live_grep<CR>";
    }
    {
      key = "<leader>fa";
      mode = "n";
      silent = true;
      action = ":lua telescope_smart_search()<CR>";
    }
    {
      key = "<leader>fs";
      mode = "n";
      silent = true;
      action = ":Telescope lsp_workspace_symbols<CR>";
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

            clipboard = {
              enable = true;
              registers = "unnamedplus";
            };

            preventJunkFiles = true;
            searchCase = "smart";
            undoFile.enable = true;

            # direnv integration — the direnv-vim plugin automatically
            # registers `autocmd DirChanged * DirenvExport` so the shell
            # environment reloads whenever Neovim's working directory changes
            # (e.g. via :cd, :lcd, or neo-tree).
            utility.direnv.enable = true;

            lsp = {
              enable = true;
              formatOnSave = true;

              # How to codeactions?
              lightbulb.enable = true;
              trouble.enable = true;

              # Run zls from $PATH (e.g. provided by a project devshell/direnv)
              # instead of the nixpkgs zls pinned by nvf's preset. mkForce is
              # required because the preset also defines `cmd`.
              servers.zls.cmd = lib.mkForce ["zls"];
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

            autocomplete.blink-cmp = {
              enable = true;
              setupOpts = {
                signature = {
                  enabled = true;
                  window.border = ["" "" "" "▕" "" "" "" "▌"];
                };
                cmdline = {
                  enable = true;
                  keymap = {
                    "<Tab>" = ["show" "accept"];
                    "<CR>" = ["accept" "fallback"];
                  };
                };
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
                lsp.servers = ["ty"];
                extraDiagnostics = {
                  enable = false;
                };
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

              zig = {
                enable = true;
              };
            };

            visuals = {
              nvim-web-devicons.enable = true;
              nvim-scrollbar.enable = true;
              fidget-nvim.enable = true;
            };

            telescope = {
              enable = true;

              # nvf's default vimgrep_arguments passes `--no-ignore`, which makes
              # live_grep search gitignored files. Override to respect .gitignore
              # (drop `--no-ignore`); keep `--hidden` if you still want dotfiles.
              setupOpts.defaults.vimgrep_arguments = [
                "${pkgs.ripgrep}/bin/rg"
                "--color=never"
                "--no-heading"
                "--with-filename"
                "--line-number"
                "--column"
                "--smart-case"
              ];
            };

            luaConfigPost = ''
              function _G.telescope_smart_search()
                local builtin = require('telescope.builtin')
                vim.ui.select(
                  {'Files', 'Workspace Symbols', 'Document Symbols', 'Live Grep'},
                  {prompt = '🔍 Search project:'},
                  function(choice)
                    if choice == 'Files' then
                      builtin.find_files()
                    elseif choice == 'Workspace Symbols' then
                      builtin.lsp_workspace_symbols()
                    elseif choice == 'Document Symbols' then
                      builtin.lsp_document_symbols()
                    elseif choice == 'Live Grep' then
                      builtin.live_grep()
                    end
                  end
                )
              end
            '';
          };
        }
      ];
    }).neovim
  ];
}
