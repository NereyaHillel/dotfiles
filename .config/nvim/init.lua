vim.g.base46_cache = vim.fn.stdpath "data" .. "/base46/"
vim.g.mapleader = " "

-- Smart OS detection for Copilot's Node path
if vim.fn.isdirectory("/data/data/com.termux") == 1 then
  vim.g.copilot_node_command = "/data/data/com.termux/files/usr/bin/node"
else
  vim.g.copilot_node_command = "node" -- Standard Linux uses the default PATH
end

vim.opt.tabstop = 8 -- Number of spaces a <Tab> in the file counts for
vim.opt.shiftwidth = 8 -- Number of spaces to use for each step of (auto)indent
vim.opt.softtabstop = 8 -- Number of spaces a <Tab> counts for when editing
vim.opt.expandtab = false -- Set to false to use real tabs, true to use spaces

vim.keymap.set("n", "K", "<cmd>Lspsaga hover_doc<CR>", { desc = "Hover Documentation" })

-- bootstrap lazy and all plugins
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not vim.uv.fs_stat(lazypath) then
  local repo = "https://github.com/folke/lazy.nvim.git"
  vim.fn.system { "git", "clone", "--filter=blob:none", repo, "--branch=stable", lazypath }
end

vim.opt.rtp:prepend(lazypath)
vim.cmd('packadd termdebug')

local lazy_config = require "configs.lazy"

-- load plugins
require("lazy").setup({
  {
    "NvChad/NvChad",
    lazy = false,
    branch = "v2.5",
    import = "nvchad.plugins",
  },

  { import = "plugins" },
}, lazy_config)

-- load theme
dofile(vim.g.base46_cache .. "defaults")
dofile(vim.g.base46_cache .. "statusline")

require "options"
require "autocmds"

vim.schedule(function()
  require "mappings"
end)

