local api = vim.api
local tblextend = vim.tbl_extend
local contains = vim.tbl_contains
local tbl = table
local o = vim.o
local v = vim.v
local opt = vim.opt
local optlocal = vim.opt_local
local cmd = vim.cmd
local fn = vim.fn

local function autocmdsgroup(group_name, autocmds)
  local group = api.nvim_create_augroup(group_name, { clear = true })
  for _, autocmd in ipairs(autocmds) do
    local events, opts = autocmd[1], autocmd[2]
    opts = tblextend("keep", { group = group }, opts)
    api.nvim_create_autocmd(events, opts)
  end
end

local activenums = { 120, 150 }
local inactivenums = {}
for i = 1,999 do
  tbl.insert(inactivenums, i)
end
local activecolumns = tbl.concat(activenums, ',')
local inactivecolumns = tbl.concat(inactivenums, ',')
local highlightsexcludedfiletypes = { 'help' }

autocmdsgroup("ColorColumn", {
  {
    { "BufNewFile", "BufRead", "BufWinEnter", "WinEnter" },
    {
      callback = function()
        if not contains(highlightsexcludedfiletypes, o.filetype) then
          optlocal.colorcolumn = activecolumns
        else
          optlocal.colorcolumn = ''
        end
      end
    }
  },
  {
    { "WinLeave" },
    {
      callback = function()
        optlocal.colorcolumn = inactivecolumns
      end
    }
  },
})

--[[
autocmdsgroup("CursorLine", {
  {
    { "BufNewFile", "BufRead", "BufWinEnter", "WinEnter" },
    {
      callback = function()
        if opt.diff:get()
        or contains(highlightsexcludedfiletypes, o.filetype) then
          optlocal.cursorline = false
        else
          optlocal.cursorline = true
        end
      end
    }
  },
  {
    { "WinLeave" },
    { callback = function() optlocal.cursorline = false end }
  },
  {
    { "OptionSet" },
    {
      pattern = "diff",
      callback = function()
        local newvalue = v.option_new
        if newvalue == "1" then
          optlocal.cursorline = false
        elseif newvalue == "0" then
          optlocal.cursorline = true
        end
      end
    }
  },
})
]]

opt.hlsearch = false
autocmdsgroup("SearchHl", {
  {
    { "CmdlineEnter" },
    {
      pattern = { "/", "?" },
      callback = function() opt.hlsearch = true end
    }
  },
  {
    { "CmdlineLeave" },
    {
      pattern = { "/", "?" },
      callback = function() opt.hlsearch = false end
    }
  },
})

autocmdsgroup("TerminalSettings", {
  {
    { "TermOpen" },
    {
      callback = function()
        optlocal.number = false
        optlocal.relativenumber = false
        optlocal.signcolumn = 'no'
        optlocal.scrollback = 100000
      end
    }
  },
  {
    { "TermOpen", "BufEnter", "WinEnter" },
    {
      pattern = 'term://*',
      callback = function()
        optlocal.sidescrolloff = 0
      end
    }
  },
  --{
  --  { "TermOpen", "BufWinEnter", "WinEnter" },
  --  {
  --    pattern = 'term://*',
  --    command = 'startinsert'
  --  }
  --},
  {
    { "TermLeave", "BufLeave", "WinLeave" },
    {
      pattern = 'term://*',
      command = 'stopinsert'
    }
  },
})

local autoretab = true
-- TODO command toggle
autocmdsgroup("AutoRetab", {
  {
    { "BufWrite" },
    {
      callback = function()
        if autoretab then
          cmd('retab')
        end
      end
    }
  },
})

local autoremovetrailingspaces = true
-- TODO command toggle
autocmdsgroup("AutoRemoveTrailingSpace", {
  {
    { "BufWrite" },
    {
      callback = function()
        if autoremovetrailingspaces then
          local winview = fn.winsaveview()
          pcall(cmd, [[%s/\v\s+$//]])
          fn.winrestview(winview)
        end
      end
    }
  },
})

autocmdsgroup("QuickfixWindow", {
  --[[
  {
    { "FileType" },
    {
      pattern = 'qf',
      command = 'wincmd L'
    }
  }
  --]]
})

autocmdsgroup("FennelMappings", {
  {
    { "FileType" },
    {
      pattern = 'fennel',
      command = [[inoremap <buffer> <a-\> λ]]
    }
  }
})
