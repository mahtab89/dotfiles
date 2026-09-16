-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here
vim.keymap.set("i", "jj", "<Esc>", { desc = "Exit insert mode" })

vim.keymap.set({ "n", "v" }, "<leader>cf", function()
  require("conform").format({
    lsp_fallback = true,
    async = false,
    timeout_ms = 3000,
  })
end, { desc = "Format" })

local python_runner = require("utils.python_runner")

vim.keymap.set("n", "<leader>r", python_runner.run_current, {
  desc = "Run current Python file",
})

vim.keymap.set("n", "<leader>R", python_runner.run_main, {
  desc = "Run project main.py",
})
