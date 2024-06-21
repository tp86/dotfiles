local helpers = require('custom.helpers')

local sep = " | "

local mode = {}

local function set_statusbar(updated)
  local pos = buffer.current_pos
  local line, col = buffer:line_from_position(pos), buffer.column[pos]
  local lines = buffer.line_count
  local lang = buffer.lexer_language
  local tabs = string.format("%s:%d", buffer.use_tabs and "T" or "S", buffer.tab_width)

  local parts = {
    lang,
    tabs,
    ("L:% 4d /% 4d"):format(line, lines),
    ("C:% 3d"):format(col),
  }
  if mode.m then
    table.insert(parts, 1, ("%s"):format(mode.m))
  end
  ui.buffer_statusbar_text = table.concat(parts, sep)
end

events.connect(events.UPDATE_UI, set_statusbar)

return {
  set_mode = function(m)
    mode.m = m
    set_statusbar()
  end,
}
