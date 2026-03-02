return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        nix = {
          "alejandra",
        },
        json = {
          "jq",
        },
        go = {
          "goimports",
          "gofmt",
        },
      },
      formatters = {
        golangci_lint = {
          command = "golangci-lint",
          args = { "run", "--fix", "$FILENAME" },
        },
      },
    },
  },
}
