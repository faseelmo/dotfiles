-----------------------------------------------------------------------------------------------------------------
-- 1. DIAGNOSTICS & UI CONFIGURATION
-------------------------------------------------------------------------------
local diagnostic_signs = {
	Error = " ",
	Warn = " ",
	Hint = "󰌵",
	Info = " ",
}

vim.diagnostic.config({
	virtual_text = false,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = diagnostic_signs.Error,
			[vim.diagnostic.severity.WARN] = diagnostic_signs.Warn,
			[vim.diagnostic.severity.INFO] = diagnostic_signs.Info,
			[vim.diagnostic.severity.HINT] = diagnostic_signs.Hint,
		},
	},
	underline = true,
	update_in_insert = false,
	severity_sort = true,
	float = {
		border = "rounded",
		source = true,
		header = "",
		prefix = "",
		focusable = true,
		style = "minimal",
	},
})

-- Decrease update time so the window pops up faster (default is 4000ms)
vim.opt.updatetime = 250

-- Automatically open the diagnostic float when you rest your cursor on an error
vim.api.nvim_create_autocmd("CursorHold", {
	group = vim.api.nvim_create_augroup("DiagnosticFloat", { clear = true }),
	callback = function()
		-- 0.10+ Native API (no 'nil' arg needed)
		vim.diagnostic.open_float({
			focus = false,
			border = "rounded",
		})
	end,
})

-------------------------------------------------------------------------------
-- 2. LSP KEYMAPS & AUTOCOMMANDS
-------------------------------------------------------------------------------
vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("UserLspConfig", {}),
	callback = function(ev)
		local client = vim.lsp.get_client_by_id(ev.data.client_id)

		-- Prevent duplicate formatting!
		-- Let efm handle Lua, let Ruff handle Python
		if client and (client.name == "lua_ls" or client.name == "basedpyright") then
			client.server_capabilities.documentFormattingProvider = false
			client.server_capabilities.documentRangeFormattingProvider = false
		end

		-- Helper to easily set keymaps with descriptions
		local function map(mode, lhs, rhs, desc)
			vim.keymap.set(mode, lhs, rhs, { buffer = ev.buf, desc = desc })
		end

		-- Hover documentation (0.12 Native Border Option)
		map("n", "K", function()
			vim.lsp.buf.hover({ border = "rounded" })
		end, "Hover Documentation")

		-- Signature help
		map("n", "<C-k>", function()
			vim.lsp.buf.signature_help({ border = "rounded" })
		end, "Signature Help")

		-- Code definitions & references
		map("n", "gd", vim.lsp.buf.definition, "Go to Definition")
		map("n", "gD", vim.lsp.buf.declaration, "Go to Declaration")
		map("n", "gr", vim.lsp.buf.references, "Find References")
		map("n", "gi", vim.lsp.buf.implementation, "Go to Implementation")

		-- Code actions & renaming
		map("n", "<leader>rn", vim.lsp.buf.rename, "Rename Symbol")
		map("n", "<leader>ca", vim.lsp.buf.code_action, "Code Action")

		-- Code formatting
		map("n", "<leader>f", function()
			vim.lsp.buf.format({ async = true })
		end, "Format Document")
	end,
})

-------------------------------------------------------------------------------
-- 3. MASON & LSP SERVERS (Neovim 0.11+ / 0.12 API)
-------------------------------------------------------------------------------
require("mason").setup()

-- Configure custom server settings directly in vim.lsp.config BEFORE enabling them
vim.lsp.config["lua_ls"] = {
	settings = {
		Lua = {
			diagnostics = { globals = { "vim" } },
			workspace = {
				library = vim.api.nvim_get_runtime_file("", true),
				checkThirdParty = false,
			},
			telemetry = { enable = false },
		},
	},
}

vim.lsp.config["clangd"] = {
	cmd = {
		"clangd",
		"--background-index",
		"--clang-tidy",
		"--fallback-style=LLVM",
	},
}

vim.lsp.config["basedpyright"] = {
    settings = {
        basedpyright = {
            analysis = {
                typeCheckingMode = "standard",
                diagnosticSeverityOverrides = {
                    reportUnusedImport = "none",
                    reportUnusedVariable = "none",
                },
            },
        },
    },
}

vim.lsp.config["rust_analyzer"] = {
	settings = {
		["rust-analyzer"] = {
			check = { command = "clippy" },
		},
	},
}

vim.lsp.config["tinymist"] = {
    settings = {
        -- exportPdf = "onSave", 
        -- Standard formatter for Typst
        formatterMode = "typstyle",
    },
}

require("typst-preview").setup({open_cmd = "firefox %s -P default"})


-- Setup mason-lspconfig using automatic handlers
require("mason-lspconfig").setup({
	-- Removed "stylua" as it's a formatter, not an LSP
	ensure_installed = {
		"clangd",
		"rust_analyzer",
		"basedpyright",
		"lua_ls",
		"taplo",
		"marksman",
		"lemminx",
		"efm",
		"ruff",
    "tinymist"
	},
	handlers = {
		function(server_name)
			-- Inject cmp_nvim_lsp completion capabilities before enabling
			local cmp_lsp = require("cmp_nvim_lsp")
			local capabilities = cmp_lsp.default_capabilities()

			local config = vim.lsp.config[server_name] or {}
			config.capabilities = vim.tbl_deep_extend("force", config.capabilities or {}, capabilities)
			vim.lsp.config[server_name] = config

			-- Enable the server natively
			vim.lsp.enable(server_name)
		end,
	},
})

-------------------------------------------------------------------------------
-- 4. EFMLS CONFIGURATION (LINTING & FORMATTING)
-------------------------------------------------------------------------------
local clang_format = require("efmls-configs.formatters.clang_format")
local stylua = require("efmls-configs.formatters.stylua")
local shellcheck = require("efmls-configs.linters.shellcheck")
local shfmt = require("efmls-configs.formatters.shfmt")
local taplo = require("efmls-configs.formatters.taplo")
local prettier = require("efmls-configs.formatters.prettier")

local languages = {
	-- Python removed: handled natively by Ruff LSP now
	lua = { stylua },
	bash = { shellcheck, shfmt },
	sh = { shellcheck, shfmt },
	toml = { taplo },
	json = { prettier },
	xml = { prettier },
	urdf = { prettier },
}

vim.lsp.config["efm"] = {
	filetypes = vim.tbl_keys(languages),
	init_options = { documentFormatting = true, documentRangeFormatting = true },
	settings = {
		rootMarkers = { ".git/", "compile_commands.json" },
		languages = languages,
	},
}

-------------------------------------------------------------------------------
-- 5. AUTOCOMPLETION (nvim-cmp)
-------------------------------------------------------------------------------
local cmp = require("cmp")

cmp.setup({
	-- Leverage Neovim 0.10+ native snippet engine
	snippet = {
		expand = function(args)
			vim.snippet.expand(args.body)
		end,
	},
	window = {
		completion = cmp.config.window.bordered(),
		documentation = cmp.config.window.bordered(),
	},
	mapping = cmp.mapping.preset.insert({
		["<C-Space>"] = cmp.mapping.complete(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
		["<Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_next_item()
			else
				fallback()
			end
		end, { "i", "s" }),
		["<S-Tab>"] = cmp.mapping(function(fallback)
			if cmp.visible() then
				cmp.select_prev_item()
			else
				fallback()
			end
		end, { "i", "s" }),
	}),
	sources = cmp.config.sources({
		{
			name = "nvim_lsp",
			entry_filter = function(entry, ctx)
				-- Hide all snippets from the LSP
				return require("cmp.types").lsp.CompletionItemKind[entry:get_kind()] ~= "Snippet"
			end,
		},
		{ name = "path" },
	}, {
		{ name = "buffer" },
	}),
})
