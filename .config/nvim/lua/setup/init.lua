local fn = vim.fn
local g = vim.g

g.mapleader = ','
g.maplocalleader = ','

local nvimconfigdir = fn.stdpath('config')
local pynvimdir = nvimconfigdir .. '/pynvim'
local pypath = pynvimdir .. '/bin/python'

if fn.empty(fn.glob(pynvimdir)) > 0 then
  -- requires python 3 installed
  fn.system { 'python3', '-m', 'venv', pynvimdir }
  fn.system([[source ]] .. pynvimdir .. '/bin/activate' .. [[ && python -m pip install pynvim]])
end

g.python3_host_prog = pypath
