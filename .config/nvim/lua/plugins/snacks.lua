return {
  {
    "folke/snacks.nvim",
    opts = {
      picker = {
        -- Base-level picker settings:
        hidden = true,  -- show hidden files
        ignored = true, -- show files from .gitignore

        -- Source-specific overrides (files & buffers):
        sources = {
          files = {
            hidden = true,
            ignored = true,
          },
          buffers = {
            hidden = true,
            ignored = true,
          },
        },
      },
    },
  },
}
