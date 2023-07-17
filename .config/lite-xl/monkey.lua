local core = require "core"
local command = require "core.command"
local keymap = require "core.keymap"

local function posrel(l1, c1, l2, c2)
  if l1 < l2 then
    return -1
  elseif l1 > l2 then
    return 1
  elseif c1 < c2 then
    return -1
  elseif c1 > c2 then
    return 1
  else
    return 0
  end
end

local function currentnode()
  local doc = core.active_view.doc
  local line1, column1, line2, column2 = doc:get_selection(true)
  if doc.treesit then
    local root = doc.ts.tree:root()
    repeat
      local rangeinchild = false
      for node in root:children() do
        local startpoint = node:start_point()
        local endpoint = node:end_point()
        local startline = startpoint.row + 1
        local startcolumn = startpoint.column + 1
        local endline = endpoint.row + 1
        local endcolumn = endpoint.column + 1
        core.log("node: %d:%d-%d:%d: %s", startline, startcolumn, endline, endcolumn, node)
        local startinchild, endinchild
        if posrel(startline, startcolumn, line1, column1) <= 0 then
          startinchild = true
        end
        if posrel(endline, endcolumn, line2, column2) >= 0 then
          endinchild = true
        end
        if startinchild and endinchild then
          root = node
          rangeinchild = true
          goto continue
        end
      end
      ::continue::
    until not rangeinchild
    core.log("Current position: %d:%d-%d:%d", line1, column1, line2, column2)
    core.log("Current node: %s", root)
    local selstartline = root:start_point().row + 1
    local selstartcolumn = root:start_point().column + 1
    local selendline = root:end_point().row + 1
    local selendcolumn = root:end_point().column + 1
    doc:set_selection(selstartline, selstartcolumn, selendline, selendcolumn)
  end
end

command.add("core.docview", {
  ["monkey:get-current-node"] = currentnode,
})

keymap.add {
  ["ctrl+j"] = "monkey:get-current-node"
}

