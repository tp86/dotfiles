local helpers = require('custom.helpers')
local nop_mt = {
  __index = helpers.defer(helpers.nop),
}

local KEYMODE_CHANGED = {}

local mode_settings
mode_settings = setmetatable({
  apply = function(mode_name)
    mode_settings[mode_name]()
  end,
  insert_mode = function()
    view.element_color[view.ELEMENT_CARET] = 0x0000ff
    view.caret_period = 750
    view.caret_width = 2
  end,
  command_mode = function()
    if view.styles then
      view.element_color[view.ELEMENT_CARET] = view.styles[view.STYLE_DEFAULT].fore
    end
    view.caret_period = 0
    view.caret_width = 2
  end,
}, nop_mt)

events.connect(KEYMODE_CHANGED, mode_settings.apply)

local function connect_all(event_names, handler)
  for _, event in ipairs(event_names) do
    events.connect(event, handler)
  end
end

local set_mode = helpers.defer(function(mode_name)
  keys.mode = mode_name
  events.emit(KEYMODE_CHANGED, mode_name)
end)
local set_default_mode = set_mode 'command_mode'

connect_all({
    events.INITIALIZED,
    events.VIEW_AFTER_SWITCH,
    events.BUFFER_AFTER_SWITCH,
  }, set_default_mode)

local command_entry = require("custom.command_entry")
events.connect(command_entry.events.FOCUS, function(active)
  if not active then
    set_default_mode()
  end
end)

keys.command_mode = setmetatable({
  -- modes
  ['f'] = set_mode 'insert_mode',

  -- movements
  ['i'] = view.line_up,
  ['j'] = view.char_left,
  ['k'] = view.line_down,
  ['l'] = view.char_right,
  ['I'] = view.stuttered_page_up,
  ['K'] = view.stuttered_page_down,
  ['J'] = function()
    local _, col = helpers.get_pos()
    if col ~= 0 then
      view.vc_home_wrap()
    else
      view.para_up()
    end
  end,
  ['L'] = function()
    local line, _, pos = helpers.get_pos()
    if pos == buffer.line_end_position[line] then
      view.para_down()
    end
    view.line_end_wrap()
  end,
  ['u'] = view.word_left,
  ['o'] = view.word_right,

  -- changes


  ['a'] = helpers.apply(ui.command_entry.run, ':'),

  [' '] = {
    ['r'] = function()
      io.save_all_files()
      reset()
    end,
    ['s'] = buffer.save,
  },
}, nop_mt) -- do not propagate unknown keys

keys.insert_mode = {
  ['esc'] = set_mode 'command_mode',
}

-- prevent handling keycodes sent with AltGr in command mode
events.connect(events.KEY, function(code, modifiers)
  if keys.mode == 'command_mode' and code > 255 then
    return true
  end
end)
