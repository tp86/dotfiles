local core = require "core"
-- local command = require "core.command"
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
          local rootstartpoint, rootendpoint = root:start_point(), root:end_point()
          if not (rootstartpoint.row == startpoint.row and rootstartpoint.column == startpoint.column and
                  rootendpoint.row == endpoint.row and rootendpoint.column == endpoint.column and
                  node:child_count() ~= 0) then
            parent = root
          end
          root = node
          rangeinchild = true
        end
      end
    until not rangeinchild
    core.log("Current position: %d:%d-%d:%d", line1, column1, line2, column2)
    core.log("Current node: %s", root)
    core.log("Parent: %s", parent)
    return root, parent
  else
    core.log("no treesit for %s", doc.filename)
  end
end

local function selectnode(doc, node)
  local selstartline = node:start_point().row + 1
  local selstartcolumn = node:start_point().column + 1
  local selendline = node:end_point().row + 1
  local selendcolumn = node:end_point().column + 1
  doc:set_selection(selstartline, selstartcolumn, selendline, selendcolumn)
end

local function withcurrentnode(action)
  return function()
    local doc = core.active_view.doc
    local node, parent = currentnode(doc)
    action(doc, node, parent)
  end
end

local selectcurrentnode = withcurrentnode(selectnode)
local selectnextsibling = withcurrentnode(function(doc, node)
  local sibling = node:next_sibling()
  if sibling then
    selectnode(doc, sibling)
  end
end)

local selectprevioussibling = withcurrentnode(function(doc, node)
  local sibling = node:prev_sibling()
  if sibling then
    selectnode(doc, sibling)
  end
end)


local selectparent = withcurrentnode(function(doc, _, parent) 
  if parent then
    selectnode(doc, parent)
  end
end)

local selectchild = withcurrentnode(function(doc, node)
  local child = node:child(0)
  if child then
    selectnode(doc, child)
  end
end)

---@diagnostic disable: assign-type-mismatch
keymap.add {
  ["ctrl+i"] = selectcurrentnode,
  ["ctrl+l"] = selectnextsibling,
  ["ctrl+h"] = selectprevioussibling,
  ["ctrl+k"] = selectparent,
  ["ctrl+j"] = selectchild,
}

