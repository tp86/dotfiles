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

textadept.editing.strip_trailing_spaces = true

require('custom.keys')
require('custom.ui')
require('custom.lang')
