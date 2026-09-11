require("oil").setup({
  -- Show hidden files (like .gitignore) by default
  view_options = {
    show_hidden = true,
  },
})

vim.keymap.set("n", "<leader>e", "<cmd>Oil<CR>", { desc = "Open File Explorer (Oil)" })

