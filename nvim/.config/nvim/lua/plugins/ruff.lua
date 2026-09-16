return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        ruff = {
          init_options = {
            settings = {
              lint = {
                ignore = { "I001" },
              },
            },
          },
        },
      },
    },
  },
}
