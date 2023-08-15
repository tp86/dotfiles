local core = require "core"
local command = require "core.command"
local doc = require "core.doc"
local save = doc.save
function doc:save(filename, abs_filename)
  -- automatically convert indentation to spaces on save
  command.perform "indent-convert:tabs-to-spaces"
  --[[TODO
  -- format document
  --- first save cursor position and scroll
  local line, column = self:get_selection()
  core.log("line %d, col %d", line, column)
  local docview = core.active_view
  local scrolly = docview.scroll.y
  core.log("scroll y: %d", scrolly)
  command.perform "lsp:format-document"
  --- restore cursor position after formatting
  docview.scroll.to.y = scrolly
  self:set_selection(line, column, line, column)
  --]]
  save(self, filename, abs_filename)
end

