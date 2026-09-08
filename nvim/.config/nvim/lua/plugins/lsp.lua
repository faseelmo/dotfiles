-------------------------------------------------------------------------------
-- 1. DIAGNOSTICS & UI CONFIGURATION
-------------------------------------------------------------------------------
local diagnostic_signs = {
    Error = "\u{f057} ", -- 
    Warn = "\u{f071} ", -- 
    Hint = "\u{ea61}", -- 󰌵
    Info = "\u{f05a}", -- 
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
        vim.diagnostic.open_float(nil, {
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
        local opts = { buffer = ev.buf }

        -- Hover documentation (0.12 Native Border Option)
        vim.keymap.set("n", "K", function()
            vim.lsp.buf.hover({ border = "rounded" })
        end, opts)

        -- Signature help
        vim.keymap.set("n", "<C-k>", function()
            vim.lsp.buf.signature_help({ border = "rounded" })
        end, opts)

        -- Code definitions & references
        vim.keymap.set("n", "gd", vim.lsp.buf.definition, opts)
        vim.keymap.set("n", "gD", vim.lsp.buf.declaration, opts)
        vim.keymap.set("n", "gr", vim.lsp.buf.references, opts)
        vim.keymap.set("n", "gi", vim.lsp.buf.implementation, opts)

        -- Code actions & renaming
        vim.keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)
        vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, opts)

        -- Code formatting
        vim.keymap.set("n", "<leader>f", function()
            vim.lsp.buf.format({ async = true })
        end, opts)
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

-- Setup mason-lspconfig using automatic handlers
require("mason-lspconfig").setup({
    ensure_installed = {
        "clangd", "rust_analyzer", "basedpyright", "lua_ls", 
        "taplo", "marksman", "lemminx", "efm", "ruff", "stylua",
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

-- Rust
vim.lsp.config["rust_analyzer"] = {
    settings = {
        ["rust-analyzer"] = {
            check = { command = "clippy" },
        },
    },
}

-------------------------------------------------------------------------------
-- 4. EFMLS CONFIGURATION (LINTING & FORMATTING)
-------------------------------------------------------------------------------
local clang_format = require("efmls-configs.formatters.clang_format")
local ruff_format = require("efmls-configs.formatters.ruff")
local ruff_lint = require("efmls-configs.linters.ruff")
local stylua = require("efmls-configs.formatters.stylua")
local shellcheck = require("efmls-configs.linters.shellcheck")
local shfmt = require("efmls-configs.formatters.shfmt")
local taplo = require("efmls-configs.formatters.taplo")
local prettier = require("efmls-configs.formatters.prettier")

local languages = {
    python = { ruff_lint, ruff_format },
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
    -- Leverage Neovim 0.10+ native snippet engine (no need for LuaSnip!)
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
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Accept currently selected item.
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
        { name = "nvim_lsp" },
    }, {
        { name = "buffer" },
    }),
})
