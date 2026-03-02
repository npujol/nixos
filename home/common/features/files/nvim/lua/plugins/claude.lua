return {
  "greggh/claude-code.nvim",
  dependencies = {
    "nvim-lua/plenary.nvim", -- Required for git operations
  },
  config = function()
    require("claude-code").setup()
  end,
}

-- Another Option
-- https://github.com/coder/claudecode.nvim
