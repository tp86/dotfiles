-- local docview = require "core.docview"
-- local scroll_to_make_visible = docview.scroll_to_make_visible
-- function docview:scroll_to_make_visible(line, col)
--   scroll_to_make_visible(self, line, col)
--   local target_y = math.floor(self.size.y * 0.5)
--   local _, y = self:get_line_screen_position(line)
--   local y_diff = y - target_y
--   self.scroll.to.y = self.scroll.y + y_diff
-- end

local core = require "core"
local command = require "core.command"

local options = {
  target = 0.3
}

local function adjust()
  local docview = core.active_view
  local target_y = math.floor(docview.size.y * options.target)
  local line = docview.doc:get_selection(false)
  local _, y = docview:get_line_screen_position(line)
  local y_diff = y - target_y
  docview.scroll.to.y = docview.scroll.y + y_diff
end

command.add("core.docview", {
  ["scrolladjust:adjust"] = adjust,
})

return {
  adjust = adjust,
  options = options,
}

