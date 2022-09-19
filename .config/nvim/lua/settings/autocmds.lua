local columns = { 120, 150 }
local inactive_nums = {}
for i = 1,999 do
  table.insert(inactive_nums, i)
end
local columns = table.concat(columns, ',')
local inactive_columns = table.concat(inactive_nums, ',')

local color_column = vim.api.nvim_create_augroup("ColorColumn", {})
vim.api.nvim_create_autocmd(
  { "BufNewFile", "BufRead", "BufWinEnter", "WinEnter" },
  {
    group = color_column,
    callback = function() vim.opt_local.colorcolumn = columns end
  }
)
vim.api.nvim_create_autocmd(
  { "WinLeave" },
  {
    group = color_column,
    callback = function() vim.opt_local.colorcolumn = inactive_columns end
  }
)

local cursor_line = vim.api.nvim_create_augroup("CursorLine", {})
vim.api.nvim_create_autocmd(
  { "BufNewFile", "BufRead", "BufWinEnter", "WinEnter" },
  {
    group = cursor_line,
    callback = function()
      if vim.opt.diff:get() then
        vim.opt_local.cursorline = false
      else
        vim.opt_local.cursorline = true
      end
    end
  }
)
vim.api.nvim_create_autocmd(
  { "WinLeave" },
  {
    group = cursor_line,
    callback = function() vim.opt_local.cursorline = false end
  }
)
vim.api.nvim_create_autocmd(
  { "OptionSet" },
  {
    group = cursor_line,
    pattern = "diff",
    callback = function()
      if vim.v.option_new == "1" then
        vim.opt_local.cursorline = false
      elseif vim.v.option_new == "0" then
        vim.opt_local.cursorline = true
      end
    end
  }
)

vim.opt.hlsearch = false
local search_highlights = vim.api.nvim_create_augroup("SearchHl", {})
vim.api.nvim_create_autocmd(
  { "CmdlineEnter" },
  {
    group = search_highlights,
    pattern = { "/", "?" },
    callback = function() vim.opt.hlsearch = true end
  }
)
vim.api.nvim_create_autocmd(
  { "CmdlineLeave" },
  {
    group = search_highlights,
    pattern = { "/", "?" },
    callback = function() vim.opt.hlsearch = false end
  }
)
