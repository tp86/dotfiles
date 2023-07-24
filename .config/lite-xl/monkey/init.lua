local core = require "core"
local keymap = require "core.keymap"
local scrolladjust = require "monkey.scrolladjust"
local prototype = require "prototype"

local position = prototype:new {
  line = 0,
  column = 0,
  
  compare = function(self, other)
    if self.line < other.line then
      return -1
    elseif self.line > other.line then
      return 1
    elseif self.column < other.column then
      return -1
    elseif self.column > other.column then
      return 1
    else
      return 0
    end
  end,
}

local boundary = prototype:new {
  from = position:new(),
  to = position:new(),

  within = function(self, other)
    return self.from:compare(other.from) >= 0 and self.to:compare(other.to) <= 0
  end,
  same = function(self, other)
    return self.from:compare(other.from) == 0 and self.to:compare(other.to) == 0
  end,
  fromnode = function(self, node)
    local nodestart = node:start_point()
    local nodeend = node:end_point()
    return self:new {
      from = position:new { line = nodestart.row + 1, column = nodestart.column + 1 },
      to = position:new { line = nodeend.row + 1, column = nodeend.column + 1 },
    }
  end,
}

local function currentnode(doc)
  if doc.treesit then
    local root = doc.ts.tree:root()
    local node, parent
    local currenttree = root
    local line1, column1, line2, column2 = doc:get_selection(true)
    local selectionboundary = boundary:new {
      from = position:new { line = line1, column = column1 },
      to = position:new { line = line2, column = column2 },
    }
    repeat
      local foundchildwithin = false
      for child in currenttree:children() do
        local childboundary = boundary:fromnode(child)
        if selectionboundary:within(childboundary) then
          local currenttreeboundary = boundary:fromnode(currenttree)
          if not childboundary:same(currenttreeboundary) then
            parent = currenttree
          end
          node = child
          currenttree = child
          foundchildwithin = true
          break
        end
      end
    until not foundchildwithin
    return node, parent
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
  scrolladjust.adjust()
end

local function withcurrentnode(action)
  return function()
    local doc = core.active_view.doc
    local node, parent = currentnode(doc)
    if not node then
      node = doc.ts.tree:root()
    end
    action(doc, node, parent)
  end
end

local selectcurrentnode = withcurrentnode(selectnode)

local function withsibling(direction)
  local methodname = direction .. "_sibling"
  return withcurrentnode(function(doc, node, parent)
    local sibling = node[methodname](node)
    if not sibling then
      local nodeboundary = boundary:fromnode(node)
      for child in parent:children() do
        local childboundary = boundary:fromnode(child)
        if childboundary:same(nodeboundary) then
          sibling = child[methodname](child)
          break
        end
      end
    end
    if sibling then
      selectnode(doc, sibling)
    end
  end)
end

local selectprevioussibling = withsibling("prev")
local selectnextsibling = withsibling("next")

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

