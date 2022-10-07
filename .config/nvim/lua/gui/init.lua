local api = vim.api
local cmd = vim.cmd
local opt = vim.opt

local group = api.nvim_create_augroup('GuiConfig', { clear = true })
api.nvim_create_autocmd({ "UIEnter" }, {
  group = group,
  callback = function()
    cmd 'GuiTabline 0'
    cmd 'GuiPopupmenu 0'
    cmd 'GuiFont! Hack:h11'
    opt.guicursor = [[n-v-c-sm:block-Cursor,i-ci-ve:ver25-blinkwait200-blinkon500-blinkoff500,r-cr-o:hor20]]
  end,
})
