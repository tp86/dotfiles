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

local function nop() end

local KEYMODE_CHANGED = 'KEYMODE_CHANGED'

local mode_settings = {
  insert_mode = function()
    view.element_color[view.ELEMENT_CARET] = 0x0000ff
    view.caret_period = 750
    view.caret_width = 1
  end,
  command_mode = function()
    view.element_color[view.ELEMENT_CARET] = 0xffffff
    view.caret_period = 0
    view.caret_width = 2
  end,
}

events.connect(KEYMODE_CHANGED, function(mode_name)
  ;(mode_settings[mode_name] or nop)()
end)

local function switch_mode(mode_name)
  keys.mode = mode_name
  events.emit(KEYMODE_CHANGED, mode_name)
end

switch_mode('command_mode')

switch_mode = defer(switch_mode)

local function get_pos()
  local index = buffer.current_pos
  local line = buffer:line_from_position(index)
  local first_pos_of_line = buffer:position_from_line(line)
  local col = index - first_pos_of_line
  return line, col, index
end

keys.command_mode = setmetatable({
  -- modes
  ['f'] = switch_mode('insert_mode'),

  -- movements
  ['i'] = view.line_up,
  ['j'] = view.char_left,
  ['k'] = view.line_down,
  ['l'] = view.char_right,
  ['I'] = view.stuttered_page_up,
  ['K'] = view.stuttered_page_down,
  ['J'] = function()
    local _, col = get_pos()
    if col ~= 0 then
      view.vc_home_wrap()
    else
      view.para_up()
    end
  end,
  ['L'] = function()
    local line, _, pos = get_pos()
    if pos == buffer.line_end_position[line] then
      view.para_down()
    end
    view.line_end_wrap()
  end,
  ['u'] = view.word_left,
  ['o'] = view.word_right,

  -- changes


  ['a'] = apply(ui.command_entry.run, ':'),

  [' '] = {
    ['r'] = function()
      buffer.save()
      reset()
    end,
    ['s'] = buffer.save,
  },
}, {
  __index = function(_, k)
    -- do not propagate unknown keys
    return nop
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
