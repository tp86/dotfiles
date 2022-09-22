local function autocmds_group(group_name, autocmds)
  local group = vim.api.nvim_create_augroup(group_name, { clear = true })
  for _, autocmd in ipairs(autocmds) do
    local events, opts = autocmd[1], autocmd[2]
    opts = vim.tbl_extend("keep", { group = group }, opts)
    vim.api.nvim_create_autocmd(events, opts)
  end
end

local columns = { 120, 150 }
local inactive_nums = {}
for i = 1,999 do
  table.insert(inactive_nums, i)
end
local columns = table.concat(columns, ',')
local inactive_columns = table.concat(inactive_nums, ',')
local highlights_excluded_filetypes = { 'help' }

autocmds_group("ColorColumn", {
  {
    { "BufNewFile", "BufRead", "BufWinEnter", "WinEnter" },
    {
      callback = function()
        if not vim.tbl_contains(highlights_excluded_filetypes, vim.o.filetype) then
          vim.opt_local.colorcolumn = columns
        else
          vim.opt_local.colorcolumn = ''
        end
      end
    }
  },
  {
    { "WinLeave" },
    {
      callback = function()
        vim.opt_local.colorcolumn = inactive_columns
      end
    }
  },
})

autocmds_group("CursorLine", {
  {
    { "BufNewFile", "BufRead", "BufWinEnter", "WinEnter" },
    {
      callback = function()
        if vim.opt.diff:get()
        or vim.tbl_contains(highlights_excluded_filetypes, vim.o.filetype) then
          vim.opt_local.cursorline = false
        else
          vim.opt_local.cursorline = true
        end
      end
    }
  },
  {
    { "WinLeave" },
    { callback = function() vim.opt_local.cursorline = false end }
  },
  {
    { "OptionSet" },
    {
      pattern = "diff",
      callback = function()
        if vim.v.option_new == "1" then
          vim.opt_local.cursorline = false
        elseif vim.v.option_new == "0" then
          vim.opt_local.cursorline = true
        end
      end
    }
  },
})

vim.opt.hlsearch = false
autocmds_group("SearchHl", {
  {
    { "CmdlineEnter" },
    {
      pattern = { "/", "?" },
      callback = function() vim.opt.hlsearch = true end
    }
  },
  {
    { "CmdlineLeave" },
    {
      pattern = { "/", "?" },
      callback = function() vim.opt.hlsearch = false end
    }
  },
})

autocmds_group("TerminalSettings", {
  {
    { "TermOpen" },
    {
      callback = function()
        vim.opt_local.number = false
        vim.opt_local.relativenumber = false
        vim.opt_local.signcolumn = 'no'
        vim.opt_local.scrollback = 100000
      end
    }
  },
  {
    { "TermOpen", "BufEnter", "WinEnter" },
    {
      pattern = 'term://*',
      callback = function()
        vim.opt_local.sidescrolloff = 0
      end
    }
  },
  {
    { "TermOpen", "BufWinEnter", "WinEnter" },
    {
      pattern = 'term://*',
      command = 'startinsert'
    }
  },
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
autocmds_group("AutoRetab", {
  {
    { "BufWrite" },
    {
      callback = function()
        if autoretab then
          vim.cmd('retab')
        end
      end
    }
  },
})

local autoremovetrailingspaces = true
-- TODO command toggle
autocmds_group("AutoRemoveTrailingSpace", {
  {
    { "BufWrite" },
    {
      callback = function()
        if autoremovetrailingspaces then
          local winview = vim.fn.winsaveview()
          pcall(vim.cmd, '%s/\\v\\s+$//')
          vim.fn.winrestview(winview)
        end
      end
    }
  },
})

autocmds_group("ClearCmdline", {
  {
    { "CmdlineLeave" },
    {
      pattern = ':',
      callback = function()
        vim.fn.timer_start(10000, function() vim.cmd('echon', '') end)
      end
    }
  }
})

autocmds_group("QuickfixWindow", {
  {
    { "FileType" },
    {
      pattern = 'qf',
      command = 'wincmd L'
    }
  }
})
