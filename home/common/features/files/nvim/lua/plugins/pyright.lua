return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {},
        basedpyright = {
          settings = {
            basedpyright = {
              analysis = {
                typeCheckingMode = "standard",
              },
            },
          },
        },
      },
    },
  },
}
