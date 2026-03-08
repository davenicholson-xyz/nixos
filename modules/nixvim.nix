{ nixvim, pkgs, ... }:

{
  imports = [ nixvim.homeModules.nixvim ];

  programs.nixvim = {
    enable = true;
    defaultEditor = true;

    colorschemes.gruvbox.enable = true;

    opts = {
      number = true;
      relativenumber = true;
      shiftwidth = 2;
      tabstop = 2;
      expandtab = true;
      wrap = false;
      ignorecase = true;
      smartcase = true;
      scrolloff = 8;
      termguicolors = true;
      clipboard = "unnamedplus";
    };

    globals.mapleader = " ";

    plugins = {
      lualine.enable = true;
      telescope.enable = true;
      oil.enable = true;      
      gitsigns.enable = true;
      which-key.enable = true;
      web-devicons.enable = true;
      bufferline.enable = true;
      vim-surround.enable = true;
      neo-tree = {
        enable = true;
        settingss = {
          close_if_last_window = true;
          filesystem = {
            follow_current_file = {
              enabled = true;
              leave_dirs_open = true;
            };
          };
        };
      };
      treesitter = {
        treesitter.enable = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
            json
            lua
            nix
            regex
            toml
            vim
            xml
            yaml
        ];
      };
    };

    keymaps = [

    {
      action = "<cmd>Neotree toggle<CR>";
      key = "<leader>e";
    }

    {
      action = "<cmd>Telescope live_grep<CR>";
      key = "<leader>fw";
    }
    {
      action = "<cmd>Telescope find_files<CR>";
      key = "<leader>ff";
    }
    {
      action = "<cmd>Telescope git_commits<CR>";
      key = "<leader>fg";
    }
    {
      action = "<cmd>Telescope oldfiles<CR>";
      key = "<leader>fh";
    }

    {
      mode = "n";
      key = "<S-l>";
      action = "<cmd>BufferLineCycleNext<cr>";
      options = {
        desc = "Cycle to next buffer";
      };
    }

    {
      mode = "n";
      key = "<S-h>";
      action = "<cmd>BufferLineCyclePrev<cr>";
      options = {
        desc = "Cycle to previous buffer";
      };
    }

    {
      mode = "n";
      key = "<leader>bd";
      action = "<cmd>bdelete<cr>";
      options = {
        desc = "Delete buffer";
      };
    }
    ];
  };
}
