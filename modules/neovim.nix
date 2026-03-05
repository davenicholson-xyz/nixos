{ config, pkgs, lib, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      telescope-nvim
      nvim-lspconfig
      nvim-treesitter
    ];

    extraLuaConfig = ''
      vim.opt.number = true
      vim.opt.relativenumber = true
      vim.opt.expandtab = true
      vim.opt.shiftwidth = 2
      vim.opt.tabstop = 2

      -- Telescope
      require("telescope").setup{}

      -- LSP
      vim.lsp.config("gopls", {})
      vim.lsp.enable("gopls")
    '';
  };

  home.packages = with pkgs; [
    gopls
    nil
  ];
}
