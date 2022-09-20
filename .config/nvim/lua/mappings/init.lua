local mapkey = vim.keymap.set
local function make_map_fn(mode)
  return function(keys, action, opts)
    opts = opts or {}
    local options = vim.tbl_extend("force", { noremap = true }, opts)
    mapkey(mode, keys, action, options)
  end
end
local nmap = make_map_fn('n')
local imap = make_map_fn('i')
local vmap = make_map_fn('v')
local tmap = make_map_fn('t')
local cmap = make_map_fn('c')
local map = make_map_fn('')

nmap('<a-h>', '<c-w>h')
nmap('<a-j>', '<c-w>j')
nmap('<a-k>', '<c-w>k')
nmap('<a-l>', '<c-w>l')
imap('<a-h>', '<c-\\><c-n><c-w>h')
imap('<a-j>', '<c-\\><c-n><c-w>j')
imap('<a-k>', '<c-\\><c-n><c-w>k')
imap('<a-l>', '<c-\\><c-n><c-w>l')
vmap('<a-h>', '<c-w>h')
vmap('<a-j>', '<c-w>j')
vmap('<a-k>', '<c-w>k')
vmap('<a-l>', '<c-w>l')
tmap('<a-h>', '<c-\\><c-n><c-w>h')
tmap('<a-j>', '<c-\\><c-n><c-w>j')
tmap('<a-k>', '<c-\\><c-n><c-w>k')
tmap('<a-l>', '<c-\\><c-n><c-w>l')
nmap('<backspace>', '<c-^>')

imap('<c-j>', '<c-n>')
imap('<c-k>', '<c-p>')

map('H', '^')
map('L', '$')

local function cwildmap(key, alt)
  cmap(key, function()
    if vim.fn.wildmenumode() == 1 then
      return alt
    else
      return key
    end
  end, { expr = true })
end

cwildmap('<c-h>', '<up>')
cwildmap('<c-l>', '<down>')
cwildmap('<c-k>', '<left>')
cwildmap('<c-j>', '<right>')
cwildmap('<left>', '<up>')
cwildmap('<right>', '<down>')
cwildmap('<up>', '<left>')
cwildmap('<down>', '<right>')

local function emptylines(count, above)
  local currentposition = vim.fn.getcurpos()
  local newposition = { currentposition[2], currentposition[5] }
  local linetoinsert = newposition[1]
  if above then
    linetoinsert = newposition[1] - 1
    newposition[1] = newposition[1] + count
  end
  local lines = {}
  for _ = 1,count do
    table.insert(lines, "")
  end
  vim.fn.append(linetoinsert, lines)
  vim.fn.cursor(newposition)
end
nmap('[ ', function() emptylines(vim.v.count1, true) end)
nmap('] ', function() emptylines(vim.v.count1) end)

tmap('<esc>', '<c-\\><c-n>')

vmap('/', 'y/<c-r>"<cr>')
vmap('?', 'y?<c-r>"<cr>')
vmap('g/', '/')
vmap('g?', '?')
