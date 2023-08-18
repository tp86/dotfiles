-- modal keybindings inspired by Emacs' Xah Fly Keys
local modal = require "plugins.modal"

local core = require "core"
local config = require "core.config"
local style = require "core.style"
local color = require "core.common".color
local command = require "core.command"
local keymap = require "core.keymap"

local function extend(tbl1, tbl2)
  for _, value in ipairs(tbl2) do
    table.insert(tbl1, value)
  end
  return tbl1
end

local function toset(tbl)
  local set = {}
  for _, value in ipairs(tbl) do
    set[value] = true
  end
  return set
end

local function doall(actions)
  return function()
    local performed = false
    for _, action in ipairs(actions) do
      if type(action) == "function" then
        performed = action()
      else
        performed = command.perform(action)
      end
      if not performed then break end
    end
    return performed
  end
end

local function tryall(actions)
  return function()
    for _, action in ipairs(actions) do
      if type(action) == "function" then
        action()
      else
        command.perform(action)
      end
    end
  end
end

local commonfallback = {
  "wheel", "hwheel", "shift+wheel", "shift+wheelup", "shift+wheeldown", "wheelup", "wheeldown",
  "shift+1lclick", "ctrl+1lclick", "1lclick", "2lclick", "3lclick",
  "ctrl+x", "ctrl+c", "ctrl+v",
}

local insertfallback = {
  "backspace", "delete",
  "return", "tab", "shift+tab", "space",
  "up", "down", "left", "right", "home", "end",
}
extend(insertfallback, commonfallback)
insertfallback = toset(insertfallback)

local commandfallback = {
  -- "ctrl+shift+p", "ctrl+p",
  "ctrl+\\",
  -- "ctrl+shift+k", "ctrl+/",
  "alt+ctrl+r",

  "escape",
  "ctrl+s", "ctrl+n",
  "ctrl+tab", "ctrl+shift+tab", "ctrl+w",
  "left", "right",
}
extend(commandfallback, commonfallback)

local caret = {
  style = style.caret,
  blink = not config.disable_blink,
}

keymap.add {
  ["right"] = "find-replace:repeat-find",
  ["left"] = "find-replace:previous-find",

  ["ctrl+\\"] = function() ---@diagnostic disable-line:assign-type-mismatch
    local treeview = require "plugins.treeview"
    if not treeview.visible or core.active_view == treeview then
      command.perform "treeview:toggle-focus"
    end
    command.perform "treeview:toggle"
  end,
  ["j"] = "treeview:next",
  ["k"] = "treeview:previous",
  ["f"] = doall { "treeview:open", function()
    local treeview = require "plugins.treeview"
    if core.active_view ~= treeview then
      command.perform "treeview:toggle"
    end
  end },
  ["s"] = "treeview:new-file",
  ["shift+s"] = "treeview:new-folder",
  ["d"] = "treeview:delete",
}

modal.map {
  command = {
    -- movements
    ["f"] = modal.mode "insert",
    ["i"] = { "listbox:previous", "doc:move-to-previous-line" },
    ["k"] = { "listbox:next", "doc:move-to-next-line" },
    ["j"] = "doc:move-to-previous-char",
    ["l"] = "doc:move-to-next-char",
    ["u"] = "doc:move-to-previous-word-start",
    ["o"] = "doc:move-to-next-word-end",

    ["h"] = function()
      local doc = core.active_view.doc
      local line, column = doc:get_selection()
      local _, indent_end = doc.lines[line]:find("^%s*")
      local previousline = doc.lines[line - 1]
      indent_end = indent_end + 1
      if column > indent_end then
        doc:set_selection(line, indent_end)
      elseif column > 1 and not (previousline and previousline:match("^%s*$")) then
        command.perform "doc:move-to-start-of-line"
      else
        command.perform "doc:move-to-previous-block-start"
      end
    end,

    [";"] = function()
      local doc = core.active_view.doc
      local line, column = doc:get_selection()
      local _, indent_end = doc.lines[line]:find("^%s*")
      indent_end = indent_end + 1
      if column == #doc.lines[line] then
        command.perform "doc:move-to-next-block-end"
      elseif column < indent_end then
        doc:set_selection(line, indent_end)
      else
        command.perform "doc:move-to-end-of-line"
      end
    end,

    ["g"] = modal.submap {
      ["i"] = "doc:move-to-start-of-doc",
      ["k"] = "doc:move-to-end-of-doc",
      ["j"] = "navigate:previous",
      ["l"] = "navigate:next",

      ["g"] = "lsp:goto-definition",
      ["n"] = "lsp:find-references",
      ["s"] = doall { "doc:go-to-line", modal.mode "insert" },
    },

    ["z"] = "doc:toggle-line-comments",
    ["shift+z"] = "doc:toggle-block-comments",
    ["q"] = "lsp:format-document",

    -- selections
    ["'"] = function()
      local doc = core.active_view.doc
      local l1, c1, l2, c2 = doc:get_selection()
      doc:set_selection(l2, c2, l1, c1)
    end,
    ["shift+i"] = "doc:select-to-previous-line",
    ["shift+k"] = "doc:select-to-next-line",
    ["shift+j"] = "doc:select-to-previous-char",
    ["shift+l"] = "doc:select-to-next-char",
    ["shift+u"] = "doc:select-to-previous-word-start",
    ["shift+o"] = "doc:select-to-next-word-end",

    ["shift+h"] = function()
      local doc = core.active_view.doc
      local line, column, line2, column2 = doc:get_selection()
      local _, indent_end = doc.lines[line]:find("^%s*")
      local previousline = doc.lines[line - 1]
      indent_end = indent_end + 1
      if column > indent_end then
        doc:set_selection(line, indent_end, line2, column2)
      elseif column > 1 and not (previousline and previousline:match("^%s*$")) then
        command.perform "doc:select-to-start-of-line"
      else
        command.perform "doc:select-to-previous-block-start"
      end
    end,

    ["shift+;"] = function()
      local doc = core.active_view.doc
      local line, column, line2, column2 = doc:get_selection()
      local _, indent_end = doc.lines[line]:find("^%s*")
      indent_end = indent_end + 1
      if column == #doc.lines[line] then
        command.perform "doc:select-to-next-block-end"
      elseif column < indent_end then
        doc:set_selection(line, indent_end, line2, column2)
      else
        command.perform "doc:select-to-end-of-line"
      end
    end,

    -- editing
    ["e"] = "doc:delete-to-previous-word-start",
    ["r"] = "doc:delete-to-next-word-end",
    ["d"] = "doc:delete",
    ["y"] = "doc:undo",
    ["shift+y"] = "doc:redo",
    ["x"] = function()
      local doc = core.active_view.doc
      if not doc:has_selection() then
        command.perform "doc:select-lines"
      end
      command.perform "doc:cut"
    end,
    ["c"] = function()
      local doc = core.active_view.doc
      if not doc:has_selection() then
        command.perform "doc:select-lines"
      end
      command.perform "doc:copy"
    end,
    ["v"] = "doc:paste",
    ["ctrl+i"] = "doc:move-lines-up",
    ["ctrl+k"] = "doc:move-lines-down",
    ["ctrl+f"] = "doc:duplicate-lines",
    ["s"] = "doc:newline-below",
    ["shift+s"] = "doc:newline-above",

    -- searching
    ["n"] = "find-replace:find",
    ["shift+n"] = "regex-replace-preview:find-replace-regex",
    ["ctrl+shift+n"] = "project-search:find-regex",

    -- tabs management


    -- misc
    ["a"] = "core:find-command",
    ["ctrl+o"] = "core:find-file",

    fallback = commandfallback,
    onenter = function()
      style.caret = { color "#ff0000" }
      config.disable_blink = true
    end
  },

  insert = {
    -- ["alt+space"] = tryall { "snippets:exit", modal.mode "command" },
    ["escape"] = { "snippets:exit", modal.mode "command" },

    ["ctrl+i"] = "autocomplete:previous",
    ["ctrl+k"] = "autocomplete:next",
    ["ctrl+l"] = { "autocomplete:complete", "snippets:next-or-exit", },
    ["ctrl+j"] = "snippets:previous",

    fallback = function(key)
      return #key == 1
          or key:match("^shift%+.$")
          or insertfallback[key]
    end,
    onenter = function()
      style.caret = caret.style
      config.disable_blink = not caret.blink
    end
  }
}
modal.activate "command"

