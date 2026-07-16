-- =========================
-- Neovim configuration
-- Clean, modern (0.11+)
-- =========================

------------------------------------------------------------
-- Basics
------------------------------------------------------------

vim.g.mapleader = " "

vim.opt.hlsearch = false
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.mouse = "a"
vim.opt.clipboard = "unnamedplus"

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.expandtab = true
vim.opt.smartindent = true

vim.opt.wrap = false
vim.opt.termguicolors = true
vim.opt.ignorecase = true
vim.opt.smartcase = true

vim.opt.updatetime = 300
vim.opt.signcolumn = "yes"
vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.cursorline = true

vim.api.nvim_create_autocmd({ "InsertEnter", "WinLeave" }, {
  callback = function()
    vim.opt.cursorline = false
  end,
})

vim.api.nvim_create_autocmd({ "InsertLeave", "WinEnter" }, {
  callback = function()
    vim.opt.cursorline = true
  end,
})


------------------------------------------------------------
-- Keybindings
------------------------------------------------------------

local map = vim.keymap.set
map("n", "<leader>w", ":w<CR>", { silent = true })
map("n", "<leader>q", ":q<CR>", { silent = true })
map("i", "jk", "<Esc>", { silent = true })

------------------------------------------------------------
-- lazy.nvim bootstrap
------------------------------------------------------------

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

------------------------------------------------------------
-- Plugins (NO treesitter plugin)
------------------------------------------------------------

require("lazy").setup({

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    config = true,
  },

  {
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    event = "VeryLazy",
    config = function()
      local moss = {
        normal = {
          a = { fg = "#A8B995", bg = "#23301F", gui = "bold" },
          b = { fg = "#A8B995", bg = "#161D16" },
          c = { fg = "#A8B995", bg = "#0A0D0B" },
        },
        insert = { a = { fg = "#050706", bg = "#A3C179", gui = "bold" } },
        visual = { a = { fg = "#050706", bg = "#7EA089", gui = "bold" } },
        replace = { a = { fg = "#050706", bg = "#B85C57", gui = "bold" } },
        command = { a = { fg = "#050706", bg = "#C79545", gui = "bold" } },
        inactive = {
          a = { fg = "#6F7F69", bg = "#0A0D0B" },
          b = { fg = "#6F7F69", bg = "#0A0D0B" },
          c = { fg = "#6F7F69", bg = "#0A0D0B" },
        },
      }
      require("lualine").setup({
        options = {
          theme = moss,
          section_separators = "",
          component_separators = "",
          globalstatus = true,
        },
      })
    end,
  },

  {
    "lewis6991/gitsigns.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
      require("gitsigns").setup({
        signs = {
          add          = { text = "▎" },
          change       = { text = "▎" },
          delete       = { text = "▎" },
          topdelete    = { text = "▎" },
          changedelete = { text = "▎" },
        },
      })
    end,
  },
  {
    "nvim-telescope/telescope.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    keys = {
      { "<leader>f", function() require("telescope.builtin").find_files() end, desc = "Find files" },
      { "<leader>/", function() require("telescope.builtin").live_grep() end, desc = "Search text" },
    },
    config = function()
      require("telescope").setup({
        defaults = {
          borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
          prompt_prefix = "◍ ",
          selection_caret = "▸ ",
        },
      })
    end,
  },
  {
    "numToStr/Comment.nvim",
    config = true,
  },
  {
    "folke/which-key.nvim",
    event = "VeryLazy",
    config = true,
  },

})

------------------------------------------------------------
-- Built-in Tree-sitter (Neovim 0.11)
------------------------------------------------------------

-- Enable Tree-sitter highlighting automatically
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})


----
--- Load terminal_palette_override
---

require("terminal_palette_overrides")
