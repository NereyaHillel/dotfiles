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
        numhl = "",
      })
    end,
  },

  {
    "github/copilot.vim",
    event = "InsertEnter",
    config = function()
      -- Keep Copilot ghost text running automatically as you type
      vim.g.copilot_enabled = true

      -- Take full control of Tab so the completion menu cannot steal it
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true

      -- Tab accepts Copilot ghost text (or inserts a regular Tab if no suggestion is shown)
      vim.keymap.set("i", "<Tab>", 'copilot#Accept("\\<CR>")', {
        expr = true,
        replace_keycodes = false,
        silent = true,
      })
    end,
  },
}
