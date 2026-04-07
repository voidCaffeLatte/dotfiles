return {
  {
    "ellisonleao/gruvbox.nvim",
    opts = {
      contrast = "soft",
      transparent_mode = true,
      overrides = {
        Normal = { bg = "none" },
        NormalNC = { bg = "none" },
        SignColumn = { bg = "none" },
        EndOfBuffer = { bg = "none" },
        NormalFloat = { bg = "none" },
        FloatBorder = { bg = "none" },
      },
    },
  },
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
