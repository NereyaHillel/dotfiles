return {
  {
    "nvim-treesitter/nvim-treesitter",
    lazy = false,
    event = function()
      return {}
    end,
    branch = vim.fn.has("nvim-0.12") == 1 and "main" or "master",
    build = ":TSUpdate",
    config = function()
      -- 1. Add nvim-treesitter/runtime to rtp so Neovim 0.12 finds queries/python/highlights.scm
      local ts_runtime = vim.fn.stdpath("data") .. "/lazy/nvim-treesitter/runtime"
      if vim.fn.isdirectory(ts_runtime) == 1 then
        vim.opt.rtp:prepend(ts_runtime)
      end

      -- 2. Compile (if empty) and load NvChad base46 Gruvbox syntax & treesitter highlights
      if vim.g.base46_cache then
        if vim.fn.getfsize(vim.g.base46_cache .. "syntax") <= 10
          or vim.fn.getfsize(vim.g.base46_cache .. "treesitter") <= 10 then
          pcall(function()
            require("base46").load_all_highlights()
          end)
        end
        for _, hl_file in ipairs({ "defaults", "statusline", "devicons", "syntax", "treesitter", "lsp", "cmp" }) do
          local path = vim.g.base46_cache .. hl_file
          if vim.fn.filereadable(path) == 1 and vim.fn.getfsize(path) > 0 then
            pcall(dofile, path)
          end
        end
      end

      vim.cmd("syntax enable")

      -- 3. Exclude parsers already bundled with Neovim 0.12 (vimdoc, lua, vim, c, query, markdown)
      local languages = {
        "python", "cpp", "rust", "make", "cmake",
        "bash", "sql", "json", "yaml", "toml",
        "javascript", "typescript", "html", "css",
      }

      local has_configs, ts_configs = pcall(require, "nvim-treesitter.configs")
      if has_configs then
        ts_configs.setup({
          ensure_installed = languages,
          auto_install = true,
          highlight = { enable = true, use_languagetree = true },
          indent = { enable = true },
        })
      else
        local has_ts, ts = pcall(require, "nvim-treesitter")
        if has_ts then
          if type(ts.setup) == "function" then
            pcall(ts.setup)
          end
          if type(ts.install) == "function" and #vim.api.nvim_list_uis() > 0 then
            local missing = {}
            for _, lang in ipairs(languages) do
              if #vim.api.nvim_get_runtime_file("parser/" .. lang .. ".*", false) == 0 then
                table.insert(missing, lang)
              end
            end
            if #missing > 0 then
              local lock_dir = vim.fn.expand("~/.cache/tree-sitter/lock")
              if vim.fn.isdirectory(lock_dir) == 1 then
                vim.fn.delete(lock_dir, "rf")
              end
              pcall(ts.install, missing)
            end
          end
        end
      end

      -- 4. Highlight helper: only start Treesitter if BOTH parser and highlights.scm exist;
      --    otherwise enable Gruvbox regex syntax for the filetype (e.g. "python") immediately.
      local function highlight_buf(bufnr)
        if not vim.api.nvim_buf_is_valid(bufnr) or not vim.api.nvim_buf_is_loaded(bufnr) then
          return
        end
        if vim.bo[bufnr].buftype ~= "" then
          return
        end
        local ft = vim.bo[bufnr].filetype
        if not ft or ft == "" then
          return
        end

        local lang = vim.treesitter.language.get_lang(ft) or ft
        local has_parser = pcall(vim.treesitter.language.add, lang)
        local has_query = false
        if has_parser then
          local ok_q, q = pcall(vim.treesitter.query.get, lang, "highlights")
          has_query = ok_q and q ~= nil
        end

        if has_parser and has_query then
          if pcall(vim.treesitter.start, bufnr, lang) then
            return
          end
        end

        vim.bo[bufnr].syntax = ft
      end

      vim.api.nvim_create_autocmd({ "FileType", "BufReadPost", "BufNewFile" }, {
        group = vim.api.nvim_create_augroup("CrossPlatformTreesitter", { clear = true }),
        callback = function(args)
          highlight_buf(args.buf)
        end,
      })

      -- 5. Immediately highlight any buffers that opened before nvim-treesitter loaded
      for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
        highlight_buf(bufnr)
      end
    end,
  },

  {
    "stevearc/conform.nvim",
    event = "BufWritePre",
    config = function()
      require "configs.conform"
    end,
  },

  {
    "neovim/nvim-lspconfig",
    config = function()
      require("nvchad.configs.lspconfig").defaults()
      require "configs.lspconfig"
    end,
  },

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

  {
    "hrsh7th/nvim-cmp",
    opts = function(_, conf)
      local cmp = require("cmp")

      conf.completion = conf.completion or {}
      conf.completion.autocomplete = false

      conf.mapping["<C-Space>"] = cmp.mapping.complete()
      conf.mapping["<C-@>"] = cmp.mapping.complete()

      conf.mapping["<CR>"] = cmp.mapping.confirm({
        behavior = cmp.ConfirmBehavior.Insert,
        select = true,
      })

      conf.mapping["<C-e>"] = cmp.mapping.abort()

      conf.mapping["<Tab>"] = nil
      conf.mapping["<S-Tab>"] = nil

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
