-- Load NvChad default LSP capabilities and keymaps (including lua_ls)
require("nvchad.configs.lspconfig").defaults()

-- Ensure Mason's bin directory is always in Neovim's PATH
local mason_bin = vim.fn.stdpath("data") .. "/mason/bin"
if not string.find(vim.env.PATH or "", mason_bin, 1, true) then
  vim.env.PATH = mason_bin .. ":" .. (vim.env.PATH or "")
end

-- Map each LSP server name to its required executable binary
local servers = {
  html = "vscode-html-language-server",
  cssls = "vscode-css-language-server",
  jsonls = "vscode-json-language-server",
  ts_ls = "typescript-language-server",
  pyright = "pyright-langserver",
  clangd = "clangd",
  rust_analyzer = "rust-analyzer",
  bashls = "bash-language-server",
}

local available_servers = {}
for server, bin in pairs(servers) do
  if vim.fn.executable(bin) == 1 then
    table.insert(available_servers, server)
  end
end

-- Neovim 0.11+ / NvChad modern API vs legacy lspconfig fallback
if vim.lsp and type(vim.lsp.enable) == "function" then
  if #available_servers > 0 then
    vim.lsp.enable(available_servers)
  end
else
  local ok_lsp, lspconfig = pcall(require, "lspconfig")
  local ok_nvlsp, nvlsp = pcall(require, "nvchad.configs.lspconfig")
  if ok_lsp and ok_nvlsp then
    for _, lsp in ipairs(available_servers) do
      if lspconfig[lsp] then
        lspconfig[lsp].setup({
          on_attach = nvlsp.on_attach,
          on_init = nvlsp.on_init,
          capabilities = nvlsp.capabilities,
        })
      end
    end
  end
end
