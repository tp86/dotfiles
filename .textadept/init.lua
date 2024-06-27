-- override assert_type to allow different types
--[[
local at = assert_type
local error_handler = require('custom.helpers').nop
function assert_type(v, expected_type, narg)
  local ok, err = pcall(at, v, expected_type, narg)
  if not ok then
    error_handler(err) -- TODO: rewrite error location
  end
  return v
end
--]]
--[[
events.connect(events.INITIALIZED, function()
  error_handler = ui.print_silent
end)
--]]

if not CURSES then
  local function set_theme()
    local hour = os.date('*t').hour
    local theme = 'light'
    if hour < 8 or hour >= 19 then
      theme = 'dark'
    end
    view:set_theme(theme, { font = 'Hack', size = 14 })
    return true
  end
  set_theme()
  timeout(30*60, set_theme)
end

buffer.use_tabs = false
buffer.tab_width = 2
--view.h_scroll_bar = false
--view.v_scroll_bar = false
local policy = view.CARET_STRICT | view.CARET_SLOP| view.CARET_EVEN
local char_width = view:text_width(view.STYLE_DEFAULT, ' ')
view:set_x_caret_policy(policy, math.floor(10.5 * char_width))
view:set_y_caret_policy(policy, 4)
view.caret_width = 2

textadept.editing.strip_trailing_spaces = true

--[[
require('custom.keys')
require('custom.ui')
require('custom.lang')
--]]

require('custom.meow')

--[[
local lext = require('custom.lua_ext')
local with_globals = lext.with_globals
local table_overrides = lext.table_overrides
local lsp = require('lsp')
if lsp then
  lsp.log_rpc = true
  lsp.show_all_diagnostics = true

  -- does not work very well as io.get_project_root is used in multiple places including local functions like get_server
  with_globals(lsp.start, {
    io = table_overrides(io, {
      get_project_root = function(filepath, submodule)
        -- find server's root_path if configured
        -- based on original io.get_project_root implementation
        local lang = buffer.lexer_language
        local server = lsp.server_commands[lang]
        if type(server) == 'function' then
          local _, opts = server()
          server = opts
        end
        local root_pattern
        if type(server) == 'table' then
          root_pattern = server.root_pattern
        end
        if root_pattern then
          local path = buffer.filename or lfs.currentdir()
          local dir = path:match('^(.-)[/\\]?$')
          while dir do
            if lfs.attributes(dir .. '/' .. root_pattern, 'mode') == 'file' then return dir end
            dir = dir:match('^(.+)[/\\]')
          end
        end
        -- fallback to original io.get_project_root
        return io.get_project_root(filepath, submodule)
      end,
    })
  })

  lsp.server_commands.lua = {
    command = 'lua-language-server',
    root_pattern = '.luarc.json',
  }
end
--]]

--events.connect(events.MODIFIED, function(pos, mod, text, length)
--  print(pos, mod, text,length)
--  if text and #text > 0 then
--  view.call_tip_show(pos, text .. ":" .. tostring(length)) end
--end)
