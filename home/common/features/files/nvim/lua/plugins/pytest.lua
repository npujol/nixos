return {
  "richardhapb/pytest.nvim",
  dependencies = { "nvim-treesitter/nvim-treesitter" },
  opts = {
    pip_command = "pip3",
  },
  config = function(_, opts)
    require("pytest").setup(opts)
  end,
}
