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

-- log used commands for gathering statistics for ergonomic modal keymap
local perform = command.perform
function command.perform(name, ...)
  local time = system.get_time()
  local performed = perform(name, ...)
  if performed then
    core.add_thread(function()
      local commandlogfile = io.open(USERDIR .. PATHSEP .. "command.log", "a")
      if commandlogfile then
        commandlogfile:write(("%s: %s\n"):format(time, name))
        commandlogfile:close()
      end
    end)
  end
  return performed
end

-- treeview plugin extensions
local treeview = require "plugins.treeview"
local treeviewtoggle = command.map["treeview:toggle"]
command.add(treeviewtoggle.predicate, {
  ["treeview:toggle"] = function()
    if not treeview.visible or core.active_view == treeview then
      command.perform "treeview:toggle-focus"
    end
    return treeviewtoggle.perform()
  end
})
local treeviewopen = command.map["treeview:open"]
command.add(treeviewopen.predicate, {
  ["treeview:open"] = function()
    treeviewopen.perform()
    if core.active_view ~= treeview then
      command.perform "treeview:toggle"
    end
  end
})

