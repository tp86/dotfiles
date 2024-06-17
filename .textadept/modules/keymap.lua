local function defer(f)
  return function(...)
    local args = table.pack(...)
    return function()
      return f(table.unpack(args))
    end
  end
end

local function apply(f, ...)
  return defer(f)(...)
end

local function switch_mode(mode_name)
  keys.mode = mode_name
  ui.statusbar_text = mode_name
end

switch_mode('command_mode')

switch_mode = defer(switch_mode)

keys.command_mode = setmetatable({
  ['f'] = switch_mode('insert_mode'),

  ['i'] = buffer.line_up,
  ['j'] = buffer.char_left,
  ['k'] = buffer.line_down,
  ['l'] = buffer.char_right,

  ['a'] = apply(ui.command_entry.run, ':'),

  [' '] = {
    ['s'] = buffer.save,
  },
}, {
  __index = function(_, k)
    -- do not propagate unknown keys
    return function() end
  end,
})

keys.insert_mode = {
  ['esc'] = switch_mode('command_mode'),
}

-- prevent handling keycodes sent with AltGr in command mode
events.connect(events.KEY, function(code, modifiers)
  if keys.mode == 'command_mode' and code > 255 then
    return true
  end
end)
