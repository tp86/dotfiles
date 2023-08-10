local config = require "core.config"
local style = require "core.style"
local color = require "core.common".color
local command = require "core.command"
local modal = require "modal"

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

local commonfallback = {
  "wheel", "hwheel", "shift+wheel", "shift+wheelup", "shift+wheeldown", "wheelup", "wheeldown",
  "shift+1lclick", "ctrl+1lclick", "1lclick", "2lclick", "3lclick"
}
local insertfallback = {
  "backspace", "delete",
  "return", "tab", "shift+tab", "space",
  "up", "down", "left", "right"
}
extend(insertfallback, commonfallback)
insertfallback = toset(insertfallback)
local normalfallback = {
  "ctrl+shift+p", "ctrl+p", "ctrl+\\", "alt+ctrl+r", "escape", "ctrl+s",
  "ctrl+tab", "ctrl+shift+tab", "ctrl+w",
  "ctrl+x", "ctrl+c", "ctrl+v",
  "ctrl+shift+k", "ctrl+/",
}
extend(normalfallback, commonfallback)
local caret = {
  style = style.caret,
  blink = not config.disable_blink,
}
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

modal.map {
  normal = {
    ["i"] = modal.mode "insert",
    ["shift+i"] = doall { "doc:select-none", modal.mode "insert" },
    ["h"] = "doc:move-to-previous-char",
    ["j"] = "doc:move-to-next-line",
    ["k"] = "doc:move-to-previous-line",
    ["l"] = "doc:move-to-next-char",
    ["shift+h"] = "doc:select-to-previous-char",
    ["shift+j"] = "doc:select-to-next-line",
    ["shift+k"] = "doc:select-to-previous-line",
    ["shift+l"] = "doc:select-to-next-char",
    ["u"] = "doc:undo",
    ["shift+u"] = "doc:redo",
    ["o"] = "doc:newline-below",
    ["shift+o"] = "doc:newline-above",
    ["w"] = doall { "doc:select-none", "doc:select-to-previous-word-start" },
    ["shift+w"] = "doc:select-to-previous-word-start",
    ["e"] = doall { "doc:select-none", "doc:select-to-next-word-end" },
    ["shift+e"] = "doc:select-to-next-word-end",
    fallback = normalfallback,
    onenter = function()
      style.caret = { color "#ff0000" }
      config.disable_blink = true
    end,
  },
  insert = {
    ["escape"] = modal.mode "normal",
    fallback = function(key) return #key == 1 or key:match("^shift%+.$") or insertfallback[key] end,
    onenter = function()
      style.caret = caret.style
      config.disable_blink = not caret.blink
    end,
  },
}
modal.activate("normal")

