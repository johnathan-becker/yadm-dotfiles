return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },
  -- add copilot
  { "github/copilot.vim" },

  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  }
}
