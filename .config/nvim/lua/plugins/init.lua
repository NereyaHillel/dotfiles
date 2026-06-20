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

  -- GitHub Copilot (Inline suggestions)
{
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    dependencies = {
      {
        "zbirenbaum/copilot-cmp",
        config = function()
          require("copilot_cmp").setup()
        end,
      },
    },
    config = function()
      -- Smart OS detection for the Node.js executable
      local is_termux = vim.fn.isdirectory("/data/data/com.termux") == 1
      local node_path = is_termux and "/data/data/com.termux/files/usr/bin/node" or "node"

      require("copilot").setup({
        copilot_node_command = node_path, 
        
        -- Override the core watcher with Neovim's built-in file watcher
        server_opts_overrides = {
          trace = "verbose",
          settings = {
            advanced = {
              listCount = 10, -- number of completions for panel
              inlineSuggestCount = 3, -- number of completions for getCompletions
            }
          },
        },
        
        suggestion = {
          enabled = true,
          auto_trigger = true,
          keymap = {
            accept = "<C-l>",      -- Press Ctrl+l to accept the whole suggestion
            accept_word = "<C-w>", -- Press Ctrl+w to accept just the next word
            accept_line = false,
            next = "<A-]>",        -- Alt+] to cycle to the next suggestion
            prev = "<A-[>",        -- Alt+[ to cycle to the previous suggestion
            dismiss = "<C-]>",     -- Ctrl+] to dismiss it
          },
        },
        panel = { enabled = false },
      })
    end,
  },
}

