-- put user settings here
-- this module will be loaded after everything else when the application starts
-- it will be automatically reloaded when saved

local core = require "core"
local keymap = require "core.keymap"
local config = require "core.config"
local style = require "core.style"

------------------------------ Themes ----------------------------------------

-- light theme:
core.reload_module("colors.duskfox")

--------------------------- Key bindings -------------------------------------

-- key binding:
-- keymap.add { ["ctrl+escape"] = "core:quit" }

-- pass 'true' for second parameter to overwrite an existing binding
-- keymap.add({ ["ctrl+pageup"] = "root:switch-to-previous-tab" }, true)
-- keymap.add({ ["ctrl+pagedown"] = "root:switch-to-next-tab" }, true)

------------------------------- Fonts ----------------------------------------

-- customize fonts:
style.font = renderer.font.load(DATADIR .. "/fonts/FiraSans-Regular.ttf", 12 * SCALE)
-- style.code_font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMono-Regular.ttf", 14 * SCALE)
--
-- DATADIR is the location of the installed Lite XL Lua code, default color
-- schemes and fonts.
-- USERDIR is the location of the Lite XL configuration directory.
--
-- font names used by lite:
-- style.font          : user interface
-- style.big_font      : big text in welcome screen
-- style.icon_font     : icons
-- style.icon_big_font : toolbar icons
-- style.code_font     : code
--
-- the function to load the font accept a 3rd optional argument like:
--
-- {antialiasing="grayscale", hinting="full", bold=true, italic=true, underline=true, smoothing=true, strikethrough=true}
--
-- possible values are:
-- antialiasing: grayscale, subpixel
-- hinting: none, slight, full
-- bold: true, false
-- italic: true, false
-- underline: true, false
-- smoothing: true, false
-- strikethrough: true, false

------------------------------ Plugins ----------------------------------------

-- enable or disable plugin loading setting config entries:

-- enable plugins.trimwhitespace, otherwise it is disabled by default:
-- config.plugins.trimwhitespace = true
--
-- disable detectindent, otherwise it is enabled by default
-- config.plugins.detectindent = false

-- Install plugins
local PLUGINSDIR = USERDIR .. PATHSEP .. "plugins"
local plugin = {}
plugin.type = {
  raw = "raw",
  git = "git",
}
function plugin.installall(plugins)
  -- TODO
end
function plugin.makepath(spec)
  local path = PLUGINSDIR .. PATHSEP .. spec.name
  if spec.type == plugin.type.raw then
    path = path .. ".lua"
  end
  return path
end
function plugin.install(spec)
  if spec.type == plugin.type.raw then
    plugin.installraw(spec)
  end
end
function plugin.installraw(spec)
  core.add_thread(function()
    local targetfilename = plugin.makepath(spec)
    local name = spec.name

    core.log("Plugin '%s' install process starting...", name)

    local downloader = process.start {
      "sh", "-c",
      "curl --create-dirs -fLo " .. targetfilename .. " " .. spec.url
    }

    while downloader:running() do
      coroutine.yield(0.1)
    end

    local returncode = downloader:returncode()
    core.log("Plugin '%s' download process ended with result: %d", name, returncode)

    if returncode ~= 0 then
      core.log("Error occurred during downloading '%s' plugin: %s", name, downloader:read_stdout())
    end
  end)
end
function plugin.exists(spec)
  local targetfilename = plugin.makepath(spec)
  return system.get_file_info(targetfilename) ~= nil
end

local plugins = {
  {
    name = "fontconfig",
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/fontconfig.lua",
  },
}
if not plugin.exists(plugins[1]) then
  plugin.install(plugins[1])
end

------------------------ Plugin configuration ----------------------------------

-- treeview
local treeview = require "plugins.treeview"
treeview.visible = false

-- fontconfig
local fontconfig = require("plugins.fontconfig")
fontconfig.use {
  code_font = { name = "Hack", size = 12 * SCALE },
}

---------------------------- Miscellaneous -------------------------------------

-- modify list of files to ignore when indexing the project:
-- config.ignore_files = {
--   -- folders
--   "^%.svn/",        "^%.git/",   "^%.hg/",        "^CVS/", "^%.Trash/", "^%.Trash%-.*/",
--   "^node_modules/", "^%.cache/", "^__pycache__/",
--   -- files
--   "%.pyc$",         "%.pyo$",       "%.exe$",        "%.dll$",   "%.obj$", "%.o$",
--   "%.a$",           "%.lib$",       "%.so$",         "%.dylib$", "%.ncb$", "%.sdf$",
--   "%.suo$",         "%.pdb$",       "%.idb$",        "%.class$", "%.psd$", "%.db$",
--   "^desktop%.ini$", "^%.DS_Store$", "^%.directory$",
-- }

