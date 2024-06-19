local helpers = require('custom.helpers')

local function set_statusbar(updated)
  local pos = buffer.current_pos
  local line, col = buffer:line_from_position(pos), buffer.column[pos]
  local lines = buffer.line_count
  local lang = buffer.lexer_language
  local tabs = string.format("%s:%d", buffer.use_tabs and "T" or "S", buffer.tab_width)
  ui.buffer_statusbar_text = string.format("L:%d/%d\tC:%d\t%s\t%s",
    line, lines, col, lang, tabs)
end

events.connect(events.UPDATE_UI, set_statusbar)
