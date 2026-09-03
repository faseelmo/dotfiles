-- Set leader key before anything else loads
vim.g.mapleader = " "
vim.g.maplocalleader = " "

-- 1. Core Editor Settings
require("core.options")
require("core.keymaps")
require("core.autocmds")

-- 2. Custom UI Components
require("ui.statusline")
require("ui.terminal")

-- 3. Plugins & Plugin Configs
require("plugins.init")
require("plugins.nvim-tree")
require("plugins.treesitter")
require("plugins.fzf")
