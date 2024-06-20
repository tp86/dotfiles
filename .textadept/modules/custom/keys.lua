
local helpers = require('custom.helpers')
local nop_mt = {
  __index = function()
    return helpers.nop
  end,
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
local set_default_mode = function() set_mode 'command_mode' end

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

local eols = {
  [buffer.EOL_LF] = '\n',
  [buffer.EOL_CRLF] = '\r\n',
  [buffer.EOL_CR] = '\r',
}

local function open_line_below()
  -- TODO smart indent
  local pos = buffer.current_pos
  local eol_pos = buffer.line_end_position[buffer:line_from_position(pos)]
  buffer:insert_text(eol_pos, eols[buffer.eol_mode])
  buffer:goto_pos(pos)
end

local function open_line_above()
  local pos = buffer.current_pos
  local line = buffer:line_from_position(pos)
  local start_pos = buffer:find_column(line, 1)
  local eol = eols[buffer.eol_mode]
  buffer:insert_text(start_pos, eol)
  buffer:goto_pos(pos + #eol)
end

local function single_action(action)
  return function()
    return helpers.with({
      enter = function()
        buffer:begin_undo_action()
      end,
      exit = function()
        buffer:end_undo_action()
      end,
    }, action)
  end
end

keys.command_mode = setmetatable({
  -- modes
  ['f'] = function() set_mode 'insert_mode' end,

  -- movements
  ['i'] = view.line_up,
  ['j'] = view.char_left,
  ['k'] = view.line_down,
  ['l'] = view.char_right,
  ['I'] = view.stuttered_page_up,
  ['K'] = view.stuttered_page_down,
  ['J'] = function()
    local col = buffer.column[buffer.current_pos]
    if col ~= 1 then
      view.vc_home_wrap()
    else
      view.para_up()
    end
  end,
  ['L'] = function()
    local pos = buffer.current_pos
    if pos == buffer.line_end_position[buffer:line_from_position(pos)] then
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
  ['s'] = textadept.editing.paste_reindent,
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
  ['ctrl+a'] = single_action(open_line_below),
  ['ctrl+A'] = single_action(open_line_above),

  [';'] = function() ui.command_entry.run(':') end,

  [' '] = {
    ['r'] = function()
      io.save_all_files()
      reset()
    end,
    ['s'] = buffer.save,
    ['t'] = function() os.spawn("exo-open --launch TerminalEmulator", io.get_project_root()) end,
  },
}, nop_mt) -- do not propagate unknown keys

keys.insert_mode = {
  ['esc'] = set_default_mode,
}

-- prevent handling keycodes sent with AltGr in command mode
events.connect(events.KEY, function(code, modifiers)
  if keys.mode == 'command_mode' and code > 255 then
    return true
  end
end)
