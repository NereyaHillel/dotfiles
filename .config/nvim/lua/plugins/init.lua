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

      -- 3. Confirm item with Enter
      conf.mapping["<CR>"] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Insert,
        select = true,
      })

      -- 4. Close menu with Ctrl-e
      conf.mapping["<C-e>"] = cmp.mapping.abort()

      -- 5. Unbind Tab/S-Tab from nvim-cmp's internal wrapper so it doesn't corrupt Copilot's keycodes
      conf.mapping["<Tab>"] = nil
      conf.mapping["<S-Tab>"] = nil

      -- 6. Native <expr> Smart Tab:
      --    - If Ctrl-Space menu is open -> scroll down through suggestions
      --    - If menu is closed -> natively evaluate copilot#Accept() without nvim_feedkeys
      vim.keymap.set("i", "<Tab>", function()
        if cmp.visible() then
          vim.schedule(function()
            cmp.select_next_item()
          end)
          return ""
        end
        if vim.fn.exists("*copilot#Accept") == 1 then
          return vim.fn["copilot#Accept"]("\t")
        end
        return "\t"
      end, { expr = true, replace_keycodes = false, silent = true })

      -- 7. Native <expr> Smart Shift-Tab: scroll up when Ctrl-Space menu is open
      vim.keymap.set("i", "<S-Tab>", function()
        if cmp.visible() then
          vim.schedule(function()
            cmp.select_prev_item()
          end)
          return ""
        end
        return "\t"
      end, { expr = true, replace_keycodes = false, silent = true })

      return conf
    end,
  },
}
