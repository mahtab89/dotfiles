return {
  {
    "saghen/blink.cmp",
    opts = {
      keymap = {
        preset = "default",

        ["<Tab>"] = { "accept", "fallback" },
        ["<CR>"] = { "accept", "fallback" },

        ["`"] = { "select_next", "fallback" },
      },
    },
  },
}
