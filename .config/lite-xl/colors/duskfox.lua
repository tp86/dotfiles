local style  = require("core.style")
local common = require("core.common")

local function clr(base, bright)
  local colors = {}
  if base then
    colors.base = { common.color(base) }
  end
  if bright then
    colors.bright = { common.color(bright) }
  end
  return colors
end

local palette = {
  black = clr("#393552", "#47407d"),
  red = clr("#eb6f92", "#f083a2"),
  green = clr("#a3be8c", "#b1d196"),
  yellow = clr("#f6c177", "#f9cb8c"),
  blue = clr("#569fba", "#65b1cd"),
  magenta = clr("#c4a7e7", "#ccb1ed"),
  cyan = clr("#9ccfd8", "#a6dae3"),
  white = clr("#e0def4", "#e2e0f7"),
  orange = clr("#ea9a97", "#f0a4a2"),
  pink = clr("#eb98c3", "#f0a6cc"),

  comment = clr("#817c9c"),

  bg0 = clr("#191726"),
  bg1 = clr("#232136"),
  bg2 = clr("#2d2a45"),
  bg3 = clr("#373354"),
  bg4 = clr("#4b4673"),

  fg0 = clr("#eae8ff"),
  fg1 = clr("#e0def4"),
  fg2 = clr("#cdcbe0"),
  fg2_5 = clr("#9d9ab3"),
  fg3 = clr("#6e6a86"),

  sel0 = clr("#433c59"),
  sel1 = clr("#63577d"),
}

style.syntax = {}
-- ui styles
style.background = palette.bg1.base
style.background2 = palette.bg0.base
style.background3 = palette.bg0.base
style.text = palette.fg2_5.base
style.caret = palette.cyan.base
style.accent = palette.fg0.base
style.dim = palette.fg3.base
style.divider = palette.bg3.base
style.selection = palette.sel0.base
style.line_number = palette.fg3.base
style.line_number2 = palette.fg2.base
style.line_highlight = palette.bg2.base
style.scrollbar = palette.bg4.base
style.scrollbar2 = palette.bg4.base
style.scrollbar_track = palette.bg3.base
style.nagbar = clr("#ff0000").base
style.nagbar_text = palette.white.bright
-- style.nagbar_dim = clr("rgba(0, 0, 0, 0.45)").base
-- style.drag_overlay = clr("rgba(255,255,255,0.1)").base
-- style.drag_overlay_tab = clr("#93DDFA").base
style.good = palette.green.base
style.warn = palette.yellow.base
style.error = palette.red.base
style.modified = palette.blue.base

-- lite-xl builtin syntax styles
style.syntax["normal"] = palette.fg1.base
style.syntax["symbol"] = palette.cyan.base
style.syntax["comment"] = palette.comment.base
style.syntax["keyword"] = palette.magenta.base
style.syntax["keyword2"] = palette.red.base
style.syntax["number"] = palette.orange.base
style.syntax["literal"] = palette.orange.bright
style.syntax["string"] = palette.green.base
style.syntax["operator"] = palette.fg2.base
style.syntax["function"] = palette.blue.bright

-- evergreen syntax styles
style.syntax["attribute"] = palette.orange.bright
style.syntax["boolean"] = palette.orange.base
style.syntax["character"] = palette.green.base
style.syntax["conditional"] = palette.magenta.bright
style.syntax["conditional.ternary"] = palette.magenta.bright
style.syntax["constant"] = palette.orange.bright
style.syntax["constant.builtin"] = palette.orange.bright
style.syntax["define"] = palette.pink.bright
style.syntax["exception"] = palette.red.base
style.syntax["error"] = palette.red.base
style.syntax["field"] = palette.blue.base
style.syntax["float"] = palette.orange.base
style.syntax["function.call"] = palette.blue.bright
style.syntax["function.macro"] = palette.red.base
style.syntax["include"] = palette.pink.bright
style.syntax["keyword.function"] = palette.magenta.base
style.syntax["keyword.operator"] = palette.fg2.base
style.syntax["keyword.return"] = palette.red.base
style.syntax["label"] = palette.magenta.bright
style.syntax["method"] = palette.blue.bright
style.syntax["method.call"] = palette.blue.bright
style.syntax["namespace"] = palette.cyan.bright
style.syntax["number"] = palette.orange.base
style.syntax["operator"] = palette.fg2.base
style.syntax["parameter"] = palette.cyan.bright
style.syntax["preproc"] = palette.pink.bright
style.syntax["punctuation.delimiter"] = palette.fg2.base
style.syntax["punctuation.brackets"] = palette.fg2.base
style.syntax["punctuation.special"] = palette.cyan.bright
style.syntax["repeat"] = palette.magenta.bright
style.syntax["storageclass"] = palette.yellow.base
style.syntax["storageclass.lifetime"] = palette.yellow.base
style.syntax["text.diff.add"] = palette.green.base
style.syntax["text.diff.delete"] = palette.red.base
style.syntax["type"] = palette.yellow.base
style.syntax["type.builtin"] = palette.cyan.bright
style.syntax["type.definition"] = palette.yellow.base
style.syntax["type.qualifier"] = palette.yellow.base
style.syntax["variable"] = palette.white.base
style.syntax["variable.builtin"] = palette.red.base

-- lint diagnostics styles
style.lint = {}
style.lint["hint"] = palette.green.base
style.lint["error"] = palette.red.base
style.lint["warning"] = palette.yellow.base
style.lint["info"] = palette.blue.base

