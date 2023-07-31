-- put user settings here
-- this module will be loaded after everything else when the application starts
-- it will be automatically reloaded when saved

local core = require "core"
local style = require "core.style"

------------------------------ Themes ----------------------------------------

-- light theme:
-- core.reload_module("colors.summer")
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

-- lixling plugin manager setup
-- installation
-- git clone https://github.com/tunalad/lixling.git ~/.config/lite-xl 
-- NOT in the plugins directory
local ok, lixling = pcall(require, "lixling")
if not ok then
  ---@diagnostic disable-next-line: missing-parameter
  local cloning = process.start { "sh", "-c", "git clone https://github.com/tunalad/lixling.git " .. USERDIR .. "/lixling" }
  -- busy wait until process is finished, rewrite asynchronously
  while cloning:running() do ---@diagnostic disable-line: need-check-nil
    local out = cloning:read_stdout() ---@diagnostic disable-line: need-check-nil
    local err = cloning:read_stderr() ---@diagnostic disable-line: need-check-nil
    out = out or err
    if out and #out > 0 then
      core.log("Lixling cloning: " .. out)
    end
  end
  lixling = require("lixling")
end

lixling.plugins {
  autoinsert = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/autoinsert.lua",
  autosaveonfocuslost = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/autosaveonfocuslost.lua",
  bracketmatch = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/bracketmatch.lua",
  console = "https://github.com/lite-xl/console.git",
  --endwise = "https://github.com/LolsonX/endwise-lite-xl.git",
  eofnewline = "https://raw.githubusercontent.com/bokunodev/lite_modules/master/plugins/eofnewline-xl.lua", -- requires update of mod-version
  ephemeraltabs = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/ephemeral_tabs.lua",
  evergreen = {
    "https://github.com/TorchedSammy/Evergreen.lxl.git",
    "master",
    -- requires installation of tree-sitter-devel and lua-devel and luarocks setup
    table.concat({
      "plugindir=$(pwd)",
      "tmpdir=$(mktemp --directory)",
      "cd $tmpdir",
      "luarocks --lua-version " .. _VERSION:match("%d.%d") .. " download --rockspec ltreesitter --dev",
      [[sed -i -E 's/^(.*sources.*)$/\1\n"csrc\/types.c",/' ltreesitter-dev-1.rockspec]],
      "luarocks --lua-version " .. _VERSION:match("%d.%d") .. " install --local ltreesitter-dev-1.rockspec",
      "cd $plugindir",
      "rm -fr $tmpdir",
      "ln -sf " .. os.getenv("HOME") .. "/.luarocks/lib/lua/" .. _VERSION:match("%d.%d") .. "/ltreesitter.so " .. USERDIR,
      [[sed -i -E 's/^(\s*res.state = )0\s*$/\1""/' init.lua]],
    }, " && ")
  },
  fontconfig = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/fontconfig.lua",
  lfautoinsert = "https://raw.githubusercontent.com/tp86/lite-xl-plugins/main/lfautoinsert/init.lua",
  -- LSP with deps begin
  lintplus = "https://github.com/liquidev/lintplus.git",
  lsp = "https://github.com/lite-xl/lite-xl-lsp.git",
  lsp_snippets = "https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/lsp_snippets.lua",
  snippets = "https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/snippets.lua",
  widget = {
    "https://github.com/lite-xl/lite-xl-widgets.git",
    "master",
    table.concat({
      [[bash -c 'echo -e "-- mod-version:3\n$(cat init.lua)" > init.lua']],
      "mkdir -p " .. USERDIR .. "/libraries",
      "ln -s " .. USERDIR .. "/plugins/widget " .. USERDIR .. "/libraries/",
    }, " && ")
  },
  -- LSP with deps end
  lspkind = {
    "https://github.com/TorchedSammy/lite-xl-lspkind.git",
    "master",
    "mv autocomplete.lua " .. USERDIR .. "/plugins",
  },
  autocomplete = "",
  navigate = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/navigate.lua",
  nonicons = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/nonicons.lua", -- requires nonicons.ttf from https://github.com/yamatsum/nonicons/raw/6a2faf4fbdfbe353c5ae6a496740ac4bfb6d0e74/dist/nonicons.ttf in fonts directory
  selectionhighlight = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/selectionhighlight.lua",
  scm = "https://github.com/lite-xl/lite-xl-scm.git",
  language_diff = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/language_diff.lua",

  colorpreview = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/colorpreview.lua",

  -- experimental
  modal = "https://raw.githubusercontent.com/tp86/lite-xl-plugins/main/modal/init.lua",
}

-- plugins configuration
-- endwise
-- require("plugins.endwise")
-- config.plugins.endwise.enable("Lua")
-- fontconfig
local fontconfig = require("plugins.fontconfig")
fontconfig.use {
  code_font = { name = "Hack", size = 12 * SCALE },
}
-- lsp
local lspconfig = require("plugins.lsp.config")
lspconfig.sumneko_lua.setup()
-- lspkind
local lspkind = require("plugins.lspkind")
lspkind.setup {
  -- downloaded and unzipped from https://github.com/ryanoasis/nerd-fonts/releases/tag/v2.3.3
  font_raw = renderer.font.load(USERDIR .. "/fonts/Hack Regular Nerd Font Complete Mono.ttf", 12 * SCALE),
}
-- treeview
local treeview = require "plugins.treeview"
treeview.visible = false

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

