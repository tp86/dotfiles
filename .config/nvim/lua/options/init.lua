-- Common settings
local opt = vim.opt

opt.expandtab = true
local tabs = 2
opt.tabstop = tabs
opt.softtabstop = tabs
opt.shiftwidth = tabs
opt.shiftround = true
opt.smartindent = true

opt.hidden = true
opt.termguicolors = true

opt.number = true
opt.relativenumber = true
opt.numberwidth = 5
opt.signcolumn = 'yes'

opt.wrap = false
opt.list = true
opt.listchars = {
  tab = '\194\187 ',
  trail = '\194\183',
  precedes = '\226\159\170',
  extends = '\226\159\171',
}

opt.scrolloff = 2
opt.sidescrolloff = 10

opt.ignorecase = true
opt.smartcase = true

opt.splitbelow = true
opt.splitright = true

opt.showmode = false

opt.grepprg = 'rg -nH' --[[ require ripgrep installed ]]

opt.clipboard:append 'unnamedplus'

opt.laststatus = 3

-- TODO easier grepping - open results window
