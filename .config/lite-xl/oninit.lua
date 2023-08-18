-- on-init one time actions
local core = require "core"
local command = require "core.command"
local common = require "core.common"

-- on document save actions
local doc = require "core.doc"
local save = doc.save
function doc:save(filename, abs_filename)
  -- automatically convert indentation to spaces on save
  command.perform "indent-convert:tabs-to-spaces"
  save(self, filename, abs_filename)
end

-- add project_dir to statusview
local statusview = require "core.statusview"
core.status_view:add_item {
  name = "project:dir",
  alignment = statusview.Item.LEFT,
  position = 1,
  get_item = function()
    return {
      -- TODO shorten path
      common.home_encode(core.project_dir),
    }
  end,
}
local fileitem = core.status_view:get_item("doc:file")
fileitem.separator = statusview.separator2

