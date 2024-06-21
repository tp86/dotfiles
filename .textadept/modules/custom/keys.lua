local helpers = require('custom.helpers')
local nop_mt = {
  __index = function()
    return helpers.nop
  end,
}

local KEYMODE_CHANGED = {}

local modes = {
  COMMAND = 'command_mode',
  INSERT = 'insert_mode',
  SELECT = 'select_mode',
}

local mode_settings = setmetatable({
  [modes.INSERT] = function()
    view.element_color[view.ELEMENT_CARET] = 0x0000ff
    view.caret_period = 750
    view.caret_width = 2
  end,
  [modes.COMMAND] = function()
    if view.styles then
      view.element_color[view.ELEMENT_CARET] = view.styles[view.STYLE_DEFAULT].fore
    end
    view.caret_period = 0
    view.caret_width = 2
  end,
  [modes.SELECT] = function()
    view.element_color[view.ELEMENT_CARET] = 0xff00ff
    view.caret_period = 0
    view.caret_width = 2
  end,
}, {
  __call = function(settings, mode_name)
    settings[mode_name]()
  end,
})

events.connect(KEYMODE_CHANGED, mode_settings)

local function connect_all(event_names, handler)
  for _, event in ipairs(event_names) do
    events.connect(event, handler)
  end
end

local set_status_mode = require("custom.ui").set_mode
local set_mode = function(mode_name)
  keys.mode = mode_name
  set_status_mode(mode_name:sub(1, 3):upper())
  events.emit(KEYMODE_CHANGED, mode_name)
end
local set_default_mode = function() set_mode(modes.COMMAND) end

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

local movement_level
local function move_by_level_left()
  view:word_left()
end
local function at_line_end()
  local pos = buffer.current_pos
  local line = buffer.line_from_position(pos)
  return pos == buffer.line_end_position[line]
end
local function move_by_level_right()
  if at_line_end() then
    view:word_right_end()
  end
  view:word_right_end()
end
local function increase_movement_level()
  local function get_fold_level(line)
    local fold_level_mask = buffer.fold_level[line]
    local fold_level = fold_level_mask & ~buffer.FOLDLEVELBASE
    fold_level = fold_level & ~buffer.FOLDLEVELWHITEFLAG
    return fold_level & ~buffer.FOLDLEVELHEADERFLAG
  end
  local line = buffer:line_from_position(buffer.current_pos)
  local fold_level = get_fold_level(line)
  local fold_start_line = buffer.fold_parent[line]
  local fold_end_line = line
  while true do
    if fold_end_line == buffer.line_count then break end
    local level = get_fold_level(fold_end_line + 1)
    if level < fold_level then break end
    fold_end_line = fold_end_line + 1
  end
  ui.print_silent(fold_level, fold_start_line, fold_end_line)
end

keys.command_mode = setmetatable({
  -- modes
  ['f'] = function() set_mode(modes.INSERT) end,
  ['g'] = function() set_mode(modes.SELECT) end,

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
  ['u'] = move_by_level_left,
  ['o'] = move_by_level_right,
  ['U'] = function()
    increase_movement_level()
    -- set_mode(modes.SELECT)
  end,

  -- TODO which-key/helix/kakoune-like helper menu
  ['h'] = {
    ['h'] = ui.find.focus,
    ['d'] = ui.switch_buffer,
    ['f'] = io.quick_open,
    ['o'] = io.open_file,
  },

  -- changes
  ['r'] = buffer.undo,
  ['R'] = buffer.redo,
  ['d'] = function()
    buffer:char_right_extend()
    buffer:cut()
  end,
  ['s'] = textadept.editing.paste_reindent,
  ['a'] = single_action(function() -- open a new line below
    open_line_below()
    buffer:line_down()
    set_mode(modes.INSERT)
  end),
  ['A'] = single_action(function()
    open_line_above()
    buffer:line_up()
    set_mode(modes.INSERT)
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

keys.insert_mode = setmetatable({
  ['esc'] = set_default_mode,
}, {
  __index = function(_, key)
    if key:match("ctrl") or
       key:match("alt") or
       key:match("meta")
    then return helpers.nop end
  end,
})

keys.select_mode = setmetatable({
  ['esc'] = function()
    buffer:set_empty_selection(buffer.current_pos)
    set_default_mode()
  end,
  ['i'] = buffer.line_up_extend,
  ['k'] = buffer.line_down_extend,
  ['j'] = buffer.char_left_extend,
  ['l'] = buffer.char_right_extend,
  ['d'] = buffer.cut,
}, nop_mt)

-- prevent handling keycodes sent with AltGr in command mode
events.connect(events.KEY, function(code, modifiers)
  if keys.mode == modes.COMMAND and code > 255 then
    return true
  end
end)
