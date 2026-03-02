local function workspace_exists(path)
  if path:sub(1, 1) == "~" then
    path = vim.fn.expand(path)
  end
  return vim.fn.isdirectory(path) == 1
end

local valid_workspaces = {}
local potential_workspaces = {
  {
    name = "personal",
    path = "/home/nainai/nai_obsidian",
  },
  {
    name = "work",
    path = "/Users/n.pujol-mendez/Projects/personal/nai_obsidian",
  },
}

for _, workspace in ipairs(potential_workspaces) do
  if workspace_exists(workspace.path) then
    table.insert(valid_workspaces, workspace)
  end
end

-- vim.print(valid_workspaces)

return {
  "obsidian-nvim/obsidian.nvim",
  version = "*",
  lazy = true,
  ft = "markdown",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  opts = {
    workspaces = valid_workspaces,
    completion = { blink = true }
  },
}
