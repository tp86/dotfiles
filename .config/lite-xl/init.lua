-- put user settings here
-- this module will be loaded after everything else when the application starts
-- it will be automatically reloaded when saved

local core = require "core"
local config = require "core.config"
local style = require "core.style"
local command = require "core.command"

-------------------------- Global settings -----------------------------------

SCALE = 1.5

------------------------- Additional globals ---------------------------------

-- used by plugin installer
rawset(_G, "PLUGINSDIR", USERDIR .. PATHSEP .. "plugins")
rawset(_G, "PATCHESDIR", USERDIR .. PATHSEP .. "patches")
rawset(_G, "FONTSDIR", USERDIR .. PATHSEP .. "fonts")
rawset(_G, "LUAVERSION", _VERSION:match("%d.%d"))

--------------------------- Configuration ------------------------------------

config.max_project_files = 10000
config.blink_period = 1.2
config.line_limit = 120
config.undo_merge_timeout = 1.0
config.find_regex = true
config.message_timeout = 2

------------------------------ Themes ----------------------------------------

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

-- Install missing plugins on startup
do
  local plugininstaller = require "plugininstaller"
  local raw, git = plugininstaller.type.raw, plugininstaller.type.git
  local cmd, withtmpdir = plugininstaller.utils.makecmd, plugininstaller.utils.withtmpdir
  local plugins = {
    -- download single plugin file
    autoinsert = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/autoinsert.lua",
    autosaveonfocuslots = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/autosaveonfocuslost.lua",
    bracketmatch = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/bracketmatch.lua",
    colorpreview = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/colorpreview.lua",
    -- download git repository plugin
    console = git {
      "https://github.com/lite-xl/console.git",
      patch = "console.patch",
    },
    ephemeraltabs = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/ephemeral_tabs.lua",
    -- single plugin file with patch
    eofnewline = raw {
      "https://raw.githubusercontent.com/bokunodev/lite_modules/master/plugins/eofnewline-xl.lua",
      patch = "eofnewline.patch",
    },
    evergreen = git {
      "https://github.com/TorchedSammy/Evergreen.lxl.git",
      patch = "evergreen.patch",
      -- TODO update installation of custom ltreesitter as described in https://github.com/TorchedSammy/Evergreen.lxl#ltreesitter-installation
      run = cmd {
        withtmpdir {
          "luarocks --lua-version " .. LUAVERSION .. " download --rockspec ltreesitter --dev",
          [[sed -i -E 's/^(.*sources.*)$/\1\n"csrc\/types.c",/' ltreesitter-dev-1.rockspec]],
          "luarocks --lua-version " .. LUAVERSION .. " install --local ltreesitter-dev-1.rockspec",
        },
        "ln -sf " .. os.getenv("HOME") .. "/.luarocks/lib/lua/" .. LUAVERSION .. "/ltreesitter.so " .. USERDIR,
      },
    },
    fontconfig = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/fontconfig.lua",
    indent_convert = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/indent_convert.lua",
    language_java = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/language_java.lua",
    language_yaml = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/language_yaml.lua",
    lfautoinsert = raw {
      "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/lfautoinsert.lua",
      patch = "lfautoinsert.patch",
    },
    lintplus = git {
      "https://github.com/liquidev/lintplus.git",
      patch = "lintplus.patch",
    },
    -- plugin with requirements
    lsp = git {
      "https://github.com/lite-xl/lite-xl-lsp.git",
      requires = {
        "lintplus", "lsp_snippets", "snippets", "widget"
      },
      patch = "lsp.patch",
    },
    -- with utils in post-install run action
    lspkind = git {
      "https://github.com/TorchedSammy/lite-xl-lspkind.git",
      patch = "lspkind.patch",
      run = cmd {
        withtmpdir {
          "curl -fLo Hack.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip",
          "unzip Hack.zip",
          "mkdir -p " .. FONTSDIR,
          "cp 'Hack Regular Nerd Font Complete Mono.ttf' " .. FONTSDIR,
        },
        "mv autocomplete.lua " .. PLUGINSDIR,
      },
    },
    lsp_snippets = raw "https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/lsp_snippets.lua",
    modal = git {
      "https://github.com/tp86/modal.lxl",
      branch = "main",
    },
    monkey = git {
      "https://github.com/tp86/monkey.lxl",
      branch = "main",
    },
    navigate = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/navigate.lua",
    -- single plugin with post-install run action
    nonicons = raw {
      "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/nonicons.lua",
      run = ("curl --create-dirs -fLo %s %s")
          :format(FONTSDIR .. PATHSEP .. "nonicons.ttf",
            "https://github.com/yamatsum/nonicons/raw/6a2faf4fbdfbe353c5ae6a496740ac4bfb6d0e74/dist/nonicons.ttf"),
    },
    regexreplacepreview = raw "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/regexreplacepreview.lua",
    scm = git "https://github.com/lite-xl/lite-xl-scm.git",
    scroll_to_target = git {
      "https://github.com/tp86/scroll-to-target.lxl",
      branch = "main",
    },
    snippets = raw "https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/snippets.lua",
    widget = git {
      "https://github.com/lite-xl/lite-xl-widgets.git",
      targetdir = "libraries",
    },
  }
  plugininstaller.install(plugins)
end

------------------------ Plugin configuration ----------------------------------

-- built-in
config.plugins.autocomplete.min_len = 2
config.plugins.bracketmatch.color_char = true
config.plugins.drawwhitespace = {
  enabled = true,
  show_leading = false,
  show_middle = true,
  show_middle_min = 2,
  trailing_color = style.error,
}
config.plugins.trimwhitespace.enabled = true
config.plugins.lineguide.enabled = true
config.plugins.toolbarview = false
config.plugins.treeview.size = 250 * SCALE

-- treeview
local treeview = require "plugins.treeview"
treeview.visible = false

-- fontconfig
local fontconfig = require "plugins.fontconfig"
fontconfig.use {
  code_font = { name = "Hack", size = 12 * SCALE },
}

-- lsp
local lspconfig = require "plugins.lsp.config"
lspconfig.sumneko_lua.setup()

-- lintplus
config.lint.hide_inline = true

-- lspkind
local lspkind = require "plugins.lspkind"
lspkind.setup {
  font_raw = renderer.font.load(FONTSDIR .. PATHSEP .. "Hack Regular Nerd Font Complete Mono.ttf", 12 * SCALE)
}

-- integrate evergreen and scm
local highlights = require "plugins.evergreen.highlights"
local readdoc = require "plugins.scm.readdoc"
local readdoc_set_text = readdoc.set_text
function readdoc:set_text(text)
  readdoc_set_text(self, text)
  highlights.init(self)
end

-- load modal keymaps from different module (for code organization)
-- core.reload_module("keymap-modal")

-- on init one-time actions
require "oninit"

-- Experimental

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

