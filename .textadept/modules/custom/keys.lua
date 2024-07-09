local helpers = require('custom.helpers')
local nop_mt = {
  __index = function()
    return helpers.nop
  end,
}

local KEYMODE_CHANGED = "custom.keys.keymode_changed"

local modes = {
  COMMAND = 'command_mode',
  INSERT = 'insert_mode',
}

local mode_settings
mode_settings = {
  apply = function(mode_name)
    mode_settings[mode_name]()
  end,
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
}

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
local set_default_mode = function() set_mode(modes.COMMAND) end

connect_all({
  events.INITIALIZED,
  events.VIEW_AFTER_SWITCH,
  events.BUFFER_AFTER_SWITCH,
  events.RESET_AFTER,
}, set_default_mode)

-- prevent handling keycodes sent with AltGr in command mode
events.connect(events.KEY, function(code, modifiers)
  if keys.mode == modes.COMMAND and code > 255 then
    return true
  end
end)

local command_entry = require("custom.command_entry")
events.connect(command_entry.events.FOCUS, function(active)
  if not active then
    set_default_mode()
  end
end)

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

local custom_mode = require('custom.mode')
keys.command_mode = setmetatable({
  -- modes switching
  ['f'] = function() set_mode(modes.INSERT) end,

  -- movements
  ['i'] = custom_mode.prev,
  ['j'] = custom_mode.left,
  ['k'] = custom_mode.next,
  ['l'] = custom_mode.right,
  ['I'] = custom_mode.prev_extend,
  ['K'] = custom_mode.next_extend,
  ['J'] = custom_mode.left_extend,
  ['L'] = custom_mode.right_extend,
  ['u'] = custom_mode.back_word,
  ['o'] = custom_mode.next_word,
  ['U'] = custom_mode.mark_left_word,
  ['O'] = custom_mode.mark_right_word,

  --TODO which-key/helix/kakoune-like helper menu
  --['h'] = {
  --  ['h'] = ui.find.focus,
  --  ['d'] = ui.switch_buffer,
  --  ['f'] = io.quick_open,
  --  ['o'] = io.open_file,
  --},
  ['h'] = custom_mode.visit,
  ['n'] = custom_mode.search,
  ['m'] = custom_mode.line,
  ['p'] = custom_mode.in_block,
  [';'] = custom_mode.reverse_direction,
  [' '] = custom_mode.cancel,
  ['1'] = function() custom_mode.expand_n(1) end,
  ['2'] = function() custom_mode.expand_n(2) end,
  ['3'] = function() custom_mode.expand_n(3) end,
  ['4'] = function() custom_mode.expand_n(4) end,
  ['5'] = function() custom_mode.expand_n(5) end,
  ['6'] = function() custom_mode.expand_n(6) end,
  ['7'] = function() custom_mode.expand_n(7) end,
  ['9'] = function() custom_mode.expand_n(9) end,
  ['8'] = function() custom_mode.expand_n(8) end,

  -- changes
  ['r'] = buffer.undo,
  ['R'] = buffer.redo,
  ['d'] = function()
    if buffer.selection_empty then
      buffer:char_right_extend()
    end
    buffer:cut()
  end,
  ['s'] = textadept.editing.paste_reindent,
  --['a'] = single_action(function() -- opien a new line below
  --  open_line_below()
  --  buffer:line_down()
  --  set_mode(modes.INSERT)
  --end),
  --['A'] = single_action(function()
  --  open_line_above()
  --  buffer:line_up()
  --  set_mode(modes.INSERT)
  --end),
  --['ctrl+a'] = single_action(open_line_below),
  --['ctrl+A'] = single_action(open_line_above),

  ['a'] = function() ui.command_entry.run(':') end,

  --[' '] = {
  --  ['r'] = function()
  --    io.save_all_files()
  --    reset()
  --  end,
  --  ['s'] = buffer.save,
  --  ['t'] = function() os.spawn("exo-open --launch TerminalEmulator", io.get_project_root()) end,
  --},
}, nop_mt) -- do not propagate unknown keys

keys.insert_mode = setmetatable({
  ['esc'] = set_default_mode,
}, {
  __index = function(_, key)
    -- do not propagate unspecified (textadept default) keys in insert mode
    if key:match("ctrl") or
       key:match("alt") or
       key:match("meta")
    then return helpers.nop end
  end,
})

return {
  events = {
    KEYMODE_CHANGED = KEYMODE_CHANGED,
  }
}
