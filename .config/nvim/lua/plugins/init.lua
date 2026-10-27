return {
  -- Syntax Highlighting (Treesitter)
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPost", "BufNewFile" },
    cmd = { "TSInstall", "TSBufEnable", "TSBufDisable", "TSModuleInfo" },
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        -- Systems & Embedded
        "c",
        "cpp",
        "rust",
        "make",
        "cmake",
        -- Scripting & Backend
        "python",
        "bash",
        "sql",
        -- Neovim & Configs
        "lua",
        "luadoc",
        "vim",
        "vimdoc",
        "json",
        "yaml",
        "toml",
        "markdown",
        "markdown_inline",
        -- Web
        "javascript",
        "typescript",
        "html",
        "css",
      },
      auto_install = true,
      highlight = {
        enable = true,
        use_languagetree = true,
      },
      indent = {
        enable = true,
      },
    },
  },

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
      vim.keymap.set("n", "<leader>db", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle Breakpoint" })
      vim.fn.sign_define("DapBreakpoint", {
        text = "🔴",
        texthl = "DiagnosticError",
        linehl = "",
        numhl = "",
      })
    end,
  },

  -- GitHub Copilot (Cross-Platform: Termux Shim + WSL/Linux Native Node)
  {
    "github/copilot.vim",
    lazy = false,
    init = function()
      vim.g.copilot_enabled = true
      vim.g.copilot_no_tab_map = true
      vim.g.copilot_assume_mapped = true

      if vim.fn.isdirectory("/data/data/com.termux") == 1 then
        local shim = vim.fn.expand("~/.config/nvim/copilot-shim.js")
        vim.env.NODE_OPTIONS = "--require " .. shim
        vim.g.copilot_node_command = "/data/data/com.termux/files/usr/bin/node"
      else
        vim.g.copilot_node_command = vim.fn.exepath("node")
      end
    end,
  },

  -- Autocompletion (nvim-cmp): Manual Ctrl-Space popup + Smart Tab handoff
  {
    "hrsh7th/nvim-cmp",
    opts = function(_, conf)
      local cmp = require("cmp")

      -- 1. Disable automatic popup while typing
      conf.completion = conf.completion or {}
      conf.completion.autocomplete = false

      -- 2. Trigger suggestion menu ONLY on Ctrl-Space (and <C-@> for Termux/WSL/Tmux)
      conf.mapping["<C-Space>"] = cmp.mapping.complete()
      conf.mapping["<C-@>"] = cmp.mapping.complete()

      -- 3. Confirm highlighted item ONLY when pressing Enter
      conf.mapping["<CR>"] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Insert,
        select = true,
      })

      -- 4. Close menu with Ctrl-e
      conf.mapping["<C-e>"] = cmp.mapping.abort()

      -- 5. Remove nvim-cmp's default Tab/S-Tab so our unified handler controls them
      conf.mapping["<Tab>"] = nil
      conf.mapping["<S-Tab>"] = nil

      -- 6. Smart Tab:
      --    - Menu open: ONLY move highlight bar down (SelectBehavior.Select) without inserting
      --    - Menu closed: Accept Copilot ghost text
      vim.keymap.set("i", "<Tab>", function()
        if cmp.visible() then
          vim.schedule(function()
            cmp.select_next_item({ behavior = cmp.SelectBehavior.Select })
          end)
          return ""
        end
        if vim.fn.exists("*copilot#Accept") == 1 then
          return vim.fn["copilot#Accept"]("\t")
        end
        return "\t"
      end, { expr = true, replace_keycodes = false, silent = true })

      -- 7. Smart Shift-Tab: ONLY move highlight bar up without inserting
      vim.keymap.set("i", "<S-Tab>", function()
        if cmp.visible() then
          vim.schedule(function()
            cmp.select_prev_item({ behavior = cmp.SelectBehavior.Select })
          end)
          return ""
        end
        return "\t"
      end, { expr = true, replace_keycodes = false, silent = true })

      return conf
    end,
  },
}
