local fn = vim.fn

vim.g.mapleader = ' '
vim.g.maplocalleader = ' '

local nvimconfigdir = vim.fn.stdpath('config')
local pynvimdir = nvimconfigdir .. '/pynvim'
local pypath = pynvimdir .. '/bin/python'

if fn.empty(fn.glob(pynvimdir)) > 0 then
  -- requires python 3 installed
  fn.system { 'python3', '-m', 'venv', pynvimdir }
  fn.system([[source ]] .. pynvimdir .. '/bin/activate' .. [[ && python -m pip install pynvim]])
end

vim.g.python3_host_prog = pypath
