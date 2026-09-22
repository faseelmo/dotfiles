vim.pack.add({
	"https://www.github.com/nvim-tree/nvim-web-devicons",
	"https://www.github.com/iamcco/markdown-preview.nvim",
	"https://www.github.com/ibhagwan/fzf-lua",
	"https://github.com/stevearc/oil.nvim",
	{
		src = "https://github.com/nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
	},
	"https://github.com/echasnovski/mini.nvim",
	"https://www.github.com/neovim/nvim-lspconfig",
	"https://github.com/mason-org/mason.nvim",
	"https://github.com/williamboman/mason-lspconfig.nvim",
	"https://github.com/creativenull/efmls-configs-nvim",
	"https://github.com/MeanderingProgrammer/render-markdown.nvim",
  "https://github.com/chomosuke/typst-preview.nvim",

	-- Minimal Autocompletion Stack
	"https://github.com/hrsh7th/nvim-cmp",
	"https://github.com/hrsh7th/cmp-nvim-lsp",
	"https://github.com/hrsh7th/cmp-buffer",
	"https://github.com/hrsh7th/cmp-path",
})
