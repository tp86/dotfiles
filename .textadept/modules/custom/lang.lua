local with = require('custom.helpers').with

local stored = setmetatable({}, {
  __index = function(t, b)
    local v = {}
    t[b] = v
    return v
  end
})

local function restore_buffer_settings()
  local stored_buffer_settings = stored[buffer]
  if stored_buffer_settings then
    for name, value in pairs(stored_buffer_settings) do
      buffer[name] = value
    end
  end
end

local function set_buffer_proxy()
  local buf = buffer
  local proxy = setmetatable({}, {
    __index = buf,
    __newindex = function(_, key, value)
      stored[buf][key] = buf[key]
      buf[key] = value
    end,
  })
  buffer = proxy
end

local function unset_buffer_proxy()
  local buffer_mt = getmetatable(buffer)
  buffer = buffer_mt.__index
end

events.connect(events.LEXER_LOADED, function(lexer_name)
  restore_buffer_settings()
  local module_name = 'lang.' .. lexer_name
  local found = package.searchpath(module_name, package.path)
  if found then
    local loader, err = loadfile(found)
    if loader then
      with({enter = set_buffer_proxy, exit = unset_buffer_proxy}, loader)
    else print(err) end
  end
end)
