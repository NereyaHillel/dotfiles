return {
  "nvimdev/lspsaga.nvim",
  lazy = false, -- <--- THIS IS THE BRUTE FORCE FIX
  dependencies = {
    "nvim-treesitter/nvim-treesitter",
    "nvim-tree/nvim-web-devicons",
  },
  config = function()
    require("lspsaga").setup {
      ui = { border = "rounded" },
    }
  end,
  keys = {
    { "K", "<cmd>Lspsaga hover_doc<CR>", desc = "Hover Documentation" },
  },
}
