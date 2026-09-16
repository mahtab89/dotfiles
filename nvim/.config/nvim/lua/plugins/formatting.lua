return {
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        python = { "ruff_format" },
        c = { "clang_format" },
        cpp = { "clang_format" },

        javascript = { "prettierd"},
        javascriptreact = { "prettierd"},
        typescript = { "prettierd"},
        typescriptreact = { "prettierd"},

        html = { "prettierd"},
        css = { "prettierd"},
        scss = { "prettierd"},

        json = { "prettierd"},
        yaml = { "prettierd"},
        markdown = { "prettierd"},

        lua = { "stylua" },
        sh = { "shfmt" },
        bash = { "shfmt" },
      },

      format_on_save = false,
    },
  },
}
