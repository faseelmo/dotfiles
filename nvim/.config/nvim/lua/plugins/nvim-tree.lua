require("nvim-tree").setup({
  view = {
    width = 35,
    side = "right",
  },
  filters = {
    dotfiles = false,
  },
  renderer = {
    group_empty = true,
  },
  actions = {
    open_file = {
      resize_window = true,
    },
  },
  on_attach = function(bufnr)
    local api = require("nvim-tree.api")

    -- Load default nvim-tree keymaps
    api.config.mappings.default_on_attach(bufnr)

    -- Custom API-based resize shortcuts (press > or < while focused on NvimTree)
    vim.keymap.set("n", "<", function()
      api.tree.resize({ relative = 5 })
    end, { buffer = bufnr, desc = "Increase tree width" })

    vim.keymap.set("n", ">", function()
      api.tree.resize({ relative = -5 })
    end, { buffer = bufnr, desc = "Decrease tree width" })
  end,
})

vim.keymap.set("n", "<leader>e", function()
  require("nvim-tree.api").tree.toggle()
end, { desc = "Toggle NvimTree" })

-- Theme Overrides for NvimTree background dimming
local function apply_theme_overrides()
  vim.api.nvim_set_hl(0, "NvimTreeNormal", { link = "CursorLine" })
  vim.api.nvim_set_hl(0, "NvimTreeNormalNC", { link = "Normal" })
  vim.api.nvim_set_hl(0, "NvimTreeWinSeparator", { link = "LineNr" })
end

apply_theme_overrides()

local overrides = vim.api.nvim_create_augroup("ThemeOverrides", { clear = true })
vim.api.nvim_create_autocmd("ColorScheme", {
  group = overrides,
  pattern = "*",
  callback = apply_theme_overrides,
})
