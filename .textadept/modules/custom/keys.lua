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

local set_mode = function(mode_name)
  keys.mode = mode_name
  events.emit(KEYMODE_CHANGED, mode_name)
end
local set_default_mode = helpers.defer(set_mode, 'command_mode')

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

local function open_line_below()
  -- TODO smart indent
  -- TODO stay on the same column
  buffer:line_end()
  buffer:new_line()
  buffer:line_up()
end

local function open_line_above()
  local line = buffer:line_from_position(buffer.current_pos)
  buffer:line_up()
  if line > 1 then buffer:line_end() end
  buffer:new_line()
  buffer:line_down()
end

local function single_action(action)
  return helpers.defer(helpers.with, {
    enter=helpers.method(buffer, 'begin_undo_action'),
    exit=helpers.method(buffer, 'end_undo_action'),
  }, action)
end

keys.command_mode = setmetatable({
  -- modes
  ['f'] = helpers.defer(set_mode, 'insert_mode'),

  -- movements
  ['i'] = view.line_up,
  ['j'] = view.char_left,
  ['k'] = view.line_down,
  ['l'] = view.char_right,
  ['I'] = view.stuttered_page_up,
  ['K'] = view.stuttered_page_down,
  ['J'] = function()
    local _, col = helpers.get_pos()
    if col ~= 1 then
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

  -- TODO which-key/helix/kakoune-like helper menu
  ['h'] = {
    ['h'] = ui.find.focus,
    ['d'] = ui.switch_buffer,
    ['f'] = io.quick_open,
    ['o'] = io.open_file,
  },

  -- TODO selections (permanent/toggle select mode)

  -- changes
  ['r'] = buffer.undo,
  ['R'] = buffer.redo,
  ['d'] = buffer.cut,
  ['D'] = function()
    if buffer.selection_empty then return end
    buffer.clear()
  end,
  ['s'] = buffer.paste_reindent,
  ['a'] = single_action(function() -- open a new line below
    open_line_below()
    buffer:line_down()
    set_mode('insert_mode')
  end),
  ['A'] = single_action(function()
    open_line_above()
    buffer:line_up()
    set_mode('insert_mode')
  end),
  ['alt+a'] = single_action(open_line_below),
  ['alt+A'] = single_action(open_line_above),

  [';'] = helpers.defer(ui.command_entry.run, ':'),

  [' '] = {
    ['r'] = function()
      io.save_all_files()
      reset()
    end,
    ['s'] = buffer.save,
    ['t'] = helpers.defer(os.spawn, "exo-open --launch TerminalEmulator", io.get_project_root())
  },
}, nop_mt) -- do not propagate unknown keys

keys.insert_mode = {
  ['esc'] = helpers.defer(set_mode, 'command_mode'),
}

-- prevent handling keycodes sent with AltGr in command mode
events.connect(events.KEY, function(code, modifiers)
  if keys.mode == 'command_mode' and code > 255 then
    return true
  end
end)


