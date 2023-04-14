local vim = vim
local fn = vim.fn
local g = vim.g

g.mapleader = ' '
g.maplocalleader = ' '

local nvimconfigdir = fn.stdpath("config")
do -- setup python provider
  local pynvimdir = nvimconfigdir .. "/pynvim"

  if fn.empty(fn.glob(pynvimdir)) > 0 then
    -- requires python 3 installed
    fn.system { "python3", "-m", "venv", pynvimdir }
    fn.system("source " .. pynvimdir .. "/bin/activate" .. " && python -m pip install pynvim")
  end

  local pypath = pynvimdir .. "/bin/python"
  g.python3_host_prog = pypath
end

vim.cmd.syntax 'on'
