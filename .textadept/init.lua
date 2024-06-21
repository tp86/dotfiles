-- override assert_type to allow different types
local at = assert_type
local error_handler = require('custom.helpers').nop
function assert_type(v, expected_type, narg)
  local ok, err = pcall(at, v, expected_type, narg)
  if not ok then
    error_handler(err) -- TODO: rewrite error location
  end
  return v
end
--[[
events.connect(events.INITIALIZED, function()
  error_handler = ui.print_silent
end)
--]]


if not CURSES then
  view:set_theme('light', { font = 'Hack', size = 14 })
end

buffer.use_tabs = false
buffer.tab_width = 2
view.h_scroll_bar = false
view.v_scroll_bar = false
local policy = view.CARET_STRICT | view.CARET_SLOP| view.CARET_EVEN
local char_width = view:text_width(view.STYLE_DEFAULT, ' ')
view:set_x_caret_policy(policy, math.floor(10.5 * char_width))
view:set_y_caret_policy(policy, 4)

textadept.editing.strip_trailing_spaces = true

require('custom.keys')
require('custom.ui')
require('custom.lang')
