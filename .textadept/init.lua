-- override assert_type to allow different types
local at = assert_type
local error_handler = print
function assert_type(v, expected_type, narg)
  local ok, err = pcall(at, v, expected_type, narg)
  if not ok then
    error_handler(err) -- TODO: rewrite error location
  end
  return v
end
events.connect(events.INITIALIZED, function()
  error_handler = ui.print_silent
end)

if not CURSES then
  view:set_theme('light', { font = 'Hack', size = 14 })
end

-- XXX change for different languages, e.g. Lua, Go
buffer.use_tabs = false
buffer.tab_width = 2

local overrides = {}
-- TODO cleanup and prevent double-overwrite
local function store()
  local buf = buffer
  rawset(buf, overrides, {})
  local buf_proxy = setmetatable({}, {
    __index = buf,
    __newindex = function(_, key, value)
      print("storing", key, buf[key])
      buf[overrides][key] = buf[key]
      buf[key] = value
    end,
    __buffer = buf,
  })
  buffer = buf_proxy
  print("store", buffer)
end

local function restore(name)
  print('restore lexer', buffer.lexer_language)
  local buf = (getmetatable(buffer) or {}).__buffer
  print('restore', buf)
  if buf then
  print('lexer', buf.lexer_language)
    print('overrides')
    for k, v in pairs(rawget(buf, overrides)) do
      print('restoring', k, v)
      buf[k] = v
    end
    buf[overrides] = nil
    buffer = buf
    buffer:set_lexer(name)
  end
  print('exit', (buf or {}).lexer_language)
end

events.connect(events.LEXER_LOADED, function(name)
  print('lexer', buffer)
  restore(name)
  local name = 'lang.' .. name
  print(name)
  local found = package.searchpath(name, package.path)
  if found then
    print("b1", buffer)
    store()
    print("b2", buffer)
    local loader, err = loadfile(found)
    if loader then loader() else print(err) end
  end
end)

textadept.editing.strip_trailing_spaces = true

require('custom.keys')
require('custom.ui')
