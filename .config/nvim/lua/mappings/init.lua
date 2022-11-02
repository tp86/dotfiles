local mapkey = vim.keymap.set local extend = vim.tbl_extend
local fn = vim.fn
local tbl = table
local v = vim.v

local function makemapfn(mode)
  return function(keys, action, opts)
    opts = opts or {}
    local options = extend("force", { noremap = true }, opts)
    mapkey(mode, keys, action, options)
  end
end
local nmap = makemapfn('n')
local imap = makemapfn('i')
local vmap = makemapfn('v')
local tmap = makemapfn('t')
local cmap = makemapfn('c')
local map = makemapfn('')

nmap('<a-h>', '<c-w>h')
nmap('<a-j>', '<c-w>j')
nmap('<a-k>', '<c-w>k')
nmap('<a-l>', '<c-w>l')
imap('<a-h>', [[<c-\><c-n><c-w>h]])
imap('<a-j>', [[<c-\><c-n><c-w>j]])
imap('<a-k>', [[<c-\><c-n><c-w>k]])
imap('<a-l>', [[<c-\><c-n><c-w>l]])
vmap('<a-h>', '<c-w>h')
vmap('<a-j>', '<c-w>j')
vmap('<a-k>', '<c-w>k')
vmap('<a-l>', '<c-w>l')
tmap('<a-h>', [[<c-\><c-n><c-w>h]])
tmap('<a-j>', [[<c-\><c-n><c-w>j]])
tmap('<a-k>', [[<c-\><c-n><c-w>k]])
tmap('<a-l>', [[<c-\><c-n><c-w>l]])
nmap('<backspace>', '<c-^>')

imap('<c-j>', '<c-n>')
imap('<c-k>', '<c-p>')

map('H', '^')
map('L', '$')

nmap('j', 'gj')
nmap('k', 'gk')

local function cwildmap(key, alt)
  cmap(key, function()
    if fn.wildmenumode() == 1 then
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
  local currentposition = fn.getcurpos()
  local newposition = { currentposition[2], currentposition[5] }
  local linetoinsert = newposition[1]
  if above then
    linetoinsert = newposition[1] - 1
    newposition[1] = newposition[1] + count
  end
  local lines = {}
  for _ = 1,count do
    tbl.insert(lines, "")
  end
  fn.append(linetoinsert, lines)
  fn.cursor(newposition)
end
nmap('<a-O>', function() emptylines(v.count1, true) end)
nmap('<a-o>', function() emptylines(v.count1) end)

tmap('<esc>', [[<c-\><c-n>]])

vmap('/', 'y/<c-r>"<cr>')
vmap('?', 'y?<c-r>"<cr>')
vmap('g/', '/')
vmap('g?', '?')

local function iput()
  local keys = '<esc>g'
  local col = fn.col('.')
  if col == 1 then
    keys = keys .. 'P'
  else
    keys = keys .. 'p'
  end
  if col == fn.col('$') then
    keys = keys .. 'a'
  else
    keys = keys .. 'i'
  end
  return keys
end
imap('<a-v>', iput, { expr = true })
tmap('<a-v>', [[<c-\><c-n>"+pa]])

nmap('[t', '<cmd>tabprevious<cr>')
nmap(']t', '<cmd>tabnext<cr>')
