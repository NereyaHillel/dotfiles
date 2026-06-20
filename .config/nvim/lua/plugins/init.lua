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

    -- Official GitHub Copilot (Resilient on Termux)
  {
 "github/copilot.vim",
    lazy = false,
    init = function()
      -- THIS is the magic fix: Tell Copilot where Node is BEFORE it loads
      vim.g.copilot_node_command = "/data/data/com.termux/files/usr/bin/node"
      
      -- Disable the default Tab keymap to protect NvChad's autocomplete menu
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true
    end,
    config = function()
      -- Map Ctrl+l (lowercase L) to accept the suggestion
      vim.cmd('imap <silent><script><expr> <C-l> copilot#Accept("\\<CR>")')
    end,
  },

}

