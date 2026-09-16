return {
  {
    "nvim-neo-tree/neo-tree.nvim",
    opts = {
      open_files_do_not_replace_types = {
        "terminal",
        "Trouble",
        "qf",
        "Outline",
      },

      window = {
        position = "right",
        width = 25,
      },

      filesystem = {
        filtered_items = {
          hide_dotfiles=false,
          hide_gitignored=false
        },
        components = {
          name = function(config, node, state)
            if node.type == "directory" and node:get_id() == state.path then
              -- Show only the last folder name for the root
              return {
                text = vim.fn.fnamemodify(node.name, ":t"),
                highlight = config.highlight or "NeoTreeDirectoryName",
              }
            end

            return require("neo-tree.sources.common.components").name(
              config,
              node,
              state
            )
          end,
        },
      },
    },
  },
}
