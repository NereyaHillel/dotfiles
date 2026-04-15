local on_attach = require("nvchad.configs.lspconfig").on_attach
local on_init = require("nvchad.configs.lspconfig").on_init
local capabilities = require("nvchad.configs.lspconfig").capabilities

-- We no longer need to require the deprecated lspconfig framework
-- local lspconfig = require("lspconfig")

-- The specific LSPs for your environment
local servers = {
  "clangd", -- C/C++
  "pyright", -- Python
  "bashls", -- Bash scripting
  "jdtls", -- Java
  "html", -- HTML
}

for _, lsp in ipairs(servers) do
  -- 1. Define the configuration for the server natively
  vim.lsp.config(lsp, {
    on_attach = on_attach,
    on_init = on_init,
    capabilities = capabilities,
  })

  -- 2. Enable the server
  vim.lsp.enable(lsp)
end
