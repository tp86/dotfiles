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

local function currentnode(doc)
  local line1, column1, line2, column2 = doc:get_selection(true)
  if doc.treesit then
    local root = doc.ts.tree:root()
    local parent
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
          parent = root
          root = node
          rangeinchild = true
          goto continue
        end
      end
      ::continue::
    until not rangeinchild
    core.log("Current position: %d:%d-%d:%d", line1, column1, line2, column2)
    core.log("Current node: %s", root)
    return root, parent
  end
end

local function selectnode(doc, node)
  local selstartline = node:start_point().row + 1
  local selstartcolumn = node:start_point().column + 1
  local selendline = node:end_point().row + 1
  local selendcolumn = node:end_point().column + 1
  doc:set_selection(selstartline, selstartcolumn, selendline, selendcolumn)
end

local function selectcurrentnode()
  local doc = core.active_view.doc
  local node = currentnode(doc)
  selectnode(doc, node)
end

local function selectnextsibling()
  local doc = core.active_view.doc
  local node = currentnode(doc)
  local sibling = node:next_sibling()
  if sibling then
    selectnode(doc, sibling)
  end
end

local function selectparent()
  local doc = core.active_view.doc
  local node, parent = currentnode(doc)
  if parent then
    selectnode(doc, parent)
  end
end

command.add("core.docview", {
  ["monkey:select-current-node"] = selectcurrentnode,
  ["monkey:select-next-sibling"] = selectnextsibling,
  ["monkey:select-parent"] = selectparent,
})

keymap.add {
  ["ctrl+i"] = "monkey:select-current-node",
  ["ctrl+l"] = "monkey:select-next-sibling",
}

