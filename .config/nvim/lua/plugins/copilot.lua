return {
  "github/copilot.vim",
  event = "BufEnter",
  init = function()
    -- v:false disables the NPX auto-downloader and forces the local engine
    vim.g.copilot_version = false 
    -- Route the local engine through our memory patcher
    vim.g.copilot_node_command = vim.fn.expand("~/.config/nvim/copilot_node.sh")
  end,
}
