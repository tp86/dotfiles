local config = require "core.config"
local style = require "core.style"
local color = require "core.common".color
local command = require "core.command"
local modal = require "plugins.modal"
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
    for _, action in ipairs(actions) do
      if type(action) == "function" then
        action()
      else
        command.perform(action)
      end
    end
  end
end

local function intreeview(cmd)
  return function()
    local core = require "core"
    local treeview = require "plugins.treeview"
    if core.active_view == treeview then
      command.perform(cmd)
    else
      return false
    end
  end
end

keymap.add {
  ["ctrl+\\"] = function()
    local core = require "core"
    local treeview = require "plugins.treeview"
    if not treeview.visible or core.active_view == treeview then
      command.perform "treeview:toggle-focus"
    end
    command.perform "treeview:toggle"
  end,
  ["j"] = intreeview("treeview:next"),
  ["k"] = intreeview("treeview:previous"),
}

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

local normalfallback = {
  "ctrl+shift+p", "ctrl+p", "ctrl+\\", "alt+ctrl+r", "escape", "ctrl+s",
  "ctrl+tab", "ctrl+shift+tab", "ctrl+w",
  "ctrl+shift+k", "ctrl+/",
}
extend(normalfallback, commonfallback)

local caret = {
  style = style.caret,
  blink = not config.disable_blink,
}

modal.map {
  normal = {
    -- mode switching
    ["i"] = modal.mode "insert",
    ["shift+i"] = doall { "doc:select-none", modal.mode "insert" },
    -- basic movements
    ["h"] = "doc:move-to-previous-char",
    ["j"] = { "listbox:next", "doc:move-to-next-line", },
    ["k"] = { "listbox:previous", "doc:move-to-previous-line", },
    ["l"] = "doc:move-to-next-char",
    ["shift+h"] = "doc:select-to-previous-char",
    ["shift+j"] = "doc:select-to-next-line",
    ["shift+k"] = "doc:select-to-previous-line",
    ["shift+l"] = "doc:select-to-next-char",
    ["w"] = doall { "doc:select-none", "doc:select-to-previous-word-start" },
    ["shift+w"] = "doc:select-to-previous-word-start",
    ["e"] = doall { "doc:select-none", "doc:select-to-next-word-end" },
    ["shift+e"] = "doc:select-to-next-word-end",
    -- undo/redo
    ["u"] = "doc:undo",
    ["shift+u"] = "doc:redo",
    -- editing
    ["o"] = "doc:newline-below",
    ["shift+o"] = "doc:newline-above",
    -- miscellaneous
    -- needed for interaction with LSP plugin (multiple definitions to go to)
    ["return"] = "listbox:select",
    -- moving around
    ["shift+,"] = "navigate:previous",
    ["shift+."] = "navigate:next",
    ["alt+h"] = "root:switch-to-left",
    ["alt+j"] = "root:switch-to-down",
    ["alt+k"] = "root:switch-to-up",
    ["alt+l"] = "root:switch-to-right",
    -- searching & replacing
    ["/"] = "find-replace:find",
    ["n"] = "find-replace:repeat-find",
    ["shift+n"] = "find-replace:previous-find",
    ["shift+/"] = "regex-replace-preview:find-replace-regex",
    fallback = normalfallback,
    onenter = function()
      style.caret = { color "#ff0000" }
      config.disable_blink = true
    end,
  },
  insert = {
    ["escape"] = modal.mode "normal",
    -- easier and faster completions
    ["ctrl+j"] = "autocomplete:next",
    ["ctrl+k"] = "autocomplete:previous",
    ["ctrl+l"] = "autocomplete:complete",
    fallback = function(key) return #key == 1 or key:match("^shift%+.$") or insertfallback[key] end,
    onenter = function()
      style.caret = caret.style
      config.disable_blink = not caret.blink
    end,
  },
}
modal.activate("normal")

