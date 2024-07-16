-- indentation settings
buffer.use_tabs = false
buffer.tab_width = 2

-- scroll bars
view.h_scroll_bar = false
view.v_scroll_bar = true

do
  local caret_policy = view.CARET_STRICT | view.CARET_SLOP | view.CARET_EVEN
  local char_width = view:text_width(view.STYLE_DEFAULT, ' ')
  view:set_x_caret_policy(caret_policy, math.floor(10.5 * char_width))
  view:set_y_caret_policy(caret_policy, 4)
end
view.caret_width = 2

-- set whitespace representation
textadept.editing.strip_trailing_spaces = true
-- no need for eol since it should be stripped automatically thanks to above
do
  local u = require('cut.utils')
  u.connect_events({
    events.BUFFER_NEW,
    events.VIEW_NEW,
    events.BUFFER_AFTER_SWITCH,
    events.VIEW_AFTER_SWITCH,
    events.FILE_OPENED,
    events.FILE_AFTER_SAVE,
    events.LEXER_LOADED,
  }, function()
    -- set only in buffers/views having filename
    if not buffer.filename then
      -- seems to be inherited and needs to be set explicitly
      -- needed really only if I decide to display eol characters at some point
      view.view_eol = false
      return
    end
    --[[
    view.representation['\n'] = '⤶'
    view.representation_appearance['\t'] = view.REPRESENTATION_PLAIN
    if not CURSES and view.styles then
      view.representation_color['\t'] = view.styles[view.STYLE_INDENTGUIDE].fore
    end
    view.view_eol = true
    --]]
    if buffer.use_tabs then
      view.view_ws = view.WS_INVISIBLE
    else
      view.view_ws = view.WS_VISIBLEONLYININDENT
      view.tab_draw_mode = view.TD_LONGARROW
      view.whitespace_size = 0
    end
  end)
end

view.indentation_guides = view.IV_NONE
