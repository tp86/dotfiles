local core = require "core"
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

keymap.add {
  ["ctrl+\\"] = function() ---@diagnostic disable-line:assign-type-mismatch
    local treeview = require "plugins.treeview"
    if not treeview.visible or core.active_view == treeview then
      command.perform "treeview:toggle-focus"
    end
    command.perform "treeview:toggle"
  end,
  ["j"] = "treeview:next",
  ["k"] = "treeview:previous",
  ["o"] = doall { "treeview:open", function()
    local treeview = require "plugins.treeview"
    if core.active_view ~= treeview then
      command.perform "treeview:toggle"
    end
  end },
  ["a"] = "treeview:new-file",
  ["shift+a"] = "treeview:new-folder",
  ["d"] = "treeview:delete",
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
  "ctrl+shift+p", "ctrl+p", "ctrl+\\", "alt+ctrl+r", "escape", "ctrl+s", "ctrl+n",
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
    ["ctrl+i"] = doall { "monkey:select-current-node", "doc:scroll-to-target", },
    ["ctrl+k"] = doall { "monkey:select-parent-node", "doc:scroll-to-target", },
    ["ctrl+j"] = doall { "monkey:select-child-node", "doc:scroll-to-target", },
    ["ctrl+l"] = doall { "monkey:select-next-sibling-node", "doc:scroll-to-target", },
    ["ctrl+h"] = doall { "monkey:select-previous-sibling-node", "doc:scroll-to-target", },
    -- selections
    ["x"] = "doc:select-lines",
    ["ctrl+up"] = "doc:create-cursor-previous-line",
    ["ctrl+down"] = "doc:create-cursor-next-line",
    -- undo/redo
    ["u"] = "doc:undo",
    ["shift+u"] = "doc:redo",
    -- editing
    ["o"] = "doc:newline-below",
    ["shift+o"] = "doc:newline-above",
    ["z"] = function()
      local doc = core.active_view.doc
      if doc:has_selection() then
        command.perform "doc:delete"
      end
    end,
    ["d"] = "doc:duplicate-lines",
    -- miscellaneous
    -- needed for interaction with LSP plugin (multiple definitions to go to)
    ["return"] = "listbox:select",
    ["="] = "lsp:format-document",
    -- moving around
    ["["] = "doc:move-to-previous-page",
    ["]"] = "doc:move-to-next-page",
    ["shift+["] = "doc:select-to-previous-page",
    ["shift+]"] = "doc:select-to-next-page",
    ["shift+,"] = "navigate:previous",
    ["shift+."] = "navigate:next",
    ["alt+h"] = "root:switch-to-left",
    ["alt+j"] = "root:switch-to-down",
    ["alt+k"] = "root:switch-to-up",
    ["alt+l"] = "root:switch-to-right",
    ["g"] = modal.submap {
      ["h"] = "doc:move-to-start-of-line",
      ["l"] = "doc:move-to-end-of-line",
      ["j"] = "doc:move-to-end-of-doc",
      ["k"] = "doc:move-to-start-of-doc",
      ["shift+h"] = "doc:select-to-start-of-line",
      ["shift+l"] = "doc:select-to-end-of-line",
      ["shift+j"] = "doc:select-to-end-of-doc",
      ["shift+k"] = "doc:select-to-start-of-doc",
      ["d"] = "lsp:goto-definition",
      ["r"] = "lsp:find-references",
      ["g"] = doall { "doc:go-to-line", modal.mode "insert" },
    },
    -- searching & replacing
    ["/"] = "find-replace:find",
    ["n"] = "find-replace:repeat-find",
    -- TODO switches for repeat and toggles (sensitivity, regex) in find view
    ["shift+n"] = "find-replace:previous-find",
    ["shift+/"] = "regex-replace-preview:find-replace-regex",
    ["ctrl+shift+/"] = "project-search:find-regex",
    fallback = normalfallback,
    onenter = function()
      style.caret = { color "#ff0000" }
      config.disable_blink = true
    end,
  },
  insert = {
    ["escape"] = { "snippets:exit", modal.mode "normal", },
    -- easier and faster completions
    ["ctrl+j"] = "autocomplete:next",
    ["ctrl+k"] = "autocomplete:previous",
    ["ctrl+l"] = { "autocomplete:complete", "snippets:next-or-exit", },
    ["ctrl+h"] = "snippets:previous",
    fallback = function(key) return #key == 1 or key:match("^shift%+.$") or insertfallback[key] end,
    onenter = function()
      style.caret = caret.style
      config.disable_blink = not caret.blink
    end,
  },
}
modal.activate("normal")

