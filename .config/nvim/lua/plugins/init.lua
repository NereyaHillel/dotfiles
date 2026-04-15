return {
  -- Formatter (Auto-formats code on save)
  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require "configs.conform"
    end,
  },

  -- Language Servers (Autocomplete, error checking)
  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

  -- Debugger (For Breakpoints)
  {
    "mfussenegger/nvim-dap",
    config = function()
      -- Map <leader>db to toggle a breakpoint
      vim.keymap.set("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle Breakpoint" })
      
      -- Define the Red Circle for breakpoints
      vim.fn.sign_define("DapBreakpoint", { 
        text = "🔴", 
        texthl = "DiagnosticError", 
        linehl = "", 
        numhl = "" 
      })
    end,
  },
}
