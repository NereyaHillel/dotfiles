---@type ChadrcConfig
local M = {}

-- Cross-platform polyfill: prevent NvChad/ui colorify from crashing on Neovim < 0.12
if vim.lsp and vim.lsp.document_color == nil then
  vim.lsp.document_color = setmetatable({
    enable = function() end,
    is_enabled = function()
      return false
    end,
    color_presentation = function() end,
  }, {
    __index = function()
      return function() end
    end,
  })
end

M.base46 = {
  theme = "gruvbox",
}

M.ui = {
  theme = "gruvbox",
}

return M
