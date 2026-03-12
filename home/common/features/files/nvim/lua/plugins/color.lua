return {
  -- add gruvbox
  -- {
  --   "ellisonleao/gruvbox.nvim",
  --   config = function()
  --     require("gruvbox").setup {
  --       transparent_mode = false,
  --       contrast = "hard"
  --     }
  --   end
  -- },
  --
  -- -- Configure LazyVim to load gruvbox

  -- {
  --   "uloco/bluloco.nvim",
  --   lazy = false,
  --   priority = 1000,
  --   dependencies = { "rktjmp/lush.nvim" },
  --   config = function()
  --   end,
  -- },

  {
    "RRethy/base16-nvim",
    lazy = false,
    priority = 1000,
  },
  
  {
    "uloco/bluloco.nvim",
    lazy = false,
    priority = 1000,
    dependencies = { "rktjmp/lush.nvim" },
  },

  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "bluloco-dark",
      -- colorscheme = "gruvbox",
      -- colorscheme = "nai"
    },
  },

  {
    "NvChad/nvim-colorizer.lua",
    config = true,
  },
}
