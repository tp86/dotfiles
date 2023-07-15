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

  fg1 = clr("#eae8ff"),
}

style.syntax = {}
style.syntax["normal"] = palette.fg1.base
style.syntax["comment"] = palette.comment.base
style.syntax["keyword"] = palette.magenta.base
style.syntax["function.call"] = palette.blue.bright
style.syntax["field"] = palette.blue.base
style.syntax["variable"] = palette.white.base
style.syntax["string"] = palette.green.base

style.lint = {}
style.lint["hint"] = palette.green.base
style.lint["error"] = palette.red.base
style.lint["warning"] = palette.yellow.base
style.lint["info"] = palette.blue.base

