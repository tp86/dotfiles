vim.filetype.add {
  extension = {
    can = 'candran'
  }
}

local group = vim.api.nvim_create_augroup('CustomFiletype', { clear = true })
vim.api.nvim_create_autocmd(
  { 'FileType' },
  {
    pattern = 'candran',
    group = group,
    callback = function()
      vim.bo.syntax = 'lua'
      vim.cmd.source(vim.fn.globpath(vim.o.runtimepath, 'indent/lua.vim'))
      vim.bo.indentexpr = 'GetLuaIndent()'
    end,
  }
)
