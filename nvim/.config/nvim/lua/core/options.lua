vim.opt.termguicolors = true
vim.cmd.colorscheme("habamax")

vim.opt.exrc = true

vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.opt.wrap = false
vim.opt.scrolloff = 10 -- keep 10 lines above/below curson when scrolling
vim.opt.sidescrolloff = 10

vim.opt.tabstop = 2
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.expandtab = true
vim.opt.smartindent = true
vim.opt.autoindent = true

vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.hlsearch = true -- highlight search matches
vim.opt.incsearch = true -- show matches as you type 

vim.opt.showmatch = true -- highlight matching brackets 
vim.opt.cmdheight = 1
vim.opt.completeopt = "menuone,noinsert,noselect" -- completion options   
vim.opt.showmode = false -- do not show the mode, instead have it in status line 
vim.opt.pumheight = 10
vim.opt.pumblend = 10
vim.opt.winblend = 0
vim.opt.conceallevel = 2
vim.opt.concealcursor = ""
vim.opt.synmaxcol = 300
vim.opt.fillchars = { eob = " " }

-- Able to undo (even undoing things after you close the file) 
local undodir = vim.fn.expand("~/.vim/undodir")
if vim.fn.isdirectory(undodir) == 0 then
  -- create undodir if non existent
	vim.fn.mkdir(undodir, "p")
end

vim.opt.backup = false
vim.opt.writebackup = false
vim.opt.swapfile = false
vim.opt.undofile = true -- do create an undo file 
vim.opt.undodir = undodir
vim.opt.updatetime = 300
vim.opt.timeoutlen = 500
vim.opt.ttimeoutlen = 50
vim.opt.autoread = true
vim.opt.autowrite = false

vim.opt.hidden = true
vim.opt.errorbells = false
vim.opt.backspace = "indent,eol,start" -- better backspace behavior 
vim.opt.autochdir = false -- do not autochange dirs 
vim.opt.iskeyword:append("-") -- include - in words 
vim.opt.path:append("**") -- include subdirs in search 
vim.opt.selection = "inclusive" -- include last char in selection 
vim.opt.mouse = "a" -- enable mouse support 
-- vim.opt.clipboard:append("unnamedplus") -- copying to system clipboard
vim.opt.modifiable = true -- allow buffer modification 

-- custom cursor 
vim.opt.guicursor =
	"n-v-c:block,i-ci-ve:ver25,r-cr:hor20,o:hor50,a:blinkwait700-blinkoff400-blinkon250-Cursor/lCursor,sm:block-blinkwait175-blinkoff150-blinkon175"

-- Folding
vim.opt.foldmethod = "expr"
vim.opt.foldexpr = "v:lua.vim.treesitter.foldexpr()"
vim.opt.foldlevel = 99

vim.opt.splitbelow = true
vim.opt.splitright = true

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.diffopt:append("linematch:60")
vim.opt.redrawtime = 10000
vim.opt.maxmempattern = 20000
