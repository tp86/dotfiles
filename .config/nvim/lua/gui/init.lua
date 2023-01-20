local api = vim.api
local cmd = vim.cmd
local fn = vim.fn
local opt = vim.opt

local function execcmdifexists(command)
  if fn.exists(":" .. string.match(command[1], "%w+")) ~= 0 then
    cmd(table.concat(command, " "))
  end
end

local group = api.nvim_create_augroup('GuiConfig', { clear = true })
api.nvim_create_autocmd({ "UIEnter" }, {
  group = group,
  callback = function()
    execcmdifexists { "GuiTabline", 0 }
    execcmdifexists { "GuiPopupmenu", 0 }
    execcmdifexists { "GuiFont!", "Hack:h11" }
    opt.guicursor = [[n-v-c-sm:block-Cursor,i-ci-ve:ver25-blinkwait200-blinkon500-blinkoff500,r-cr-o:hor20]]
    opt.mouse = 'a'
  end,
})
