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
-- Plugin installer inspired by lixling, but focused only on installing missing plugins on startup and easy applying patches
-- TODO Move to separate module and refactor
-- TODO better error and misconfiguration handling
local PLUGINSDIR = USERDIR .. PATHSEP .. "plugins"
local PATCHESDIR = USERDIR .. PATHSEP .. "patches"
local FONTSDIR = USERDIR .. PATHSEP .. "fonts"
local plugin = {}
plugin.type = {
  raw = "raw",
  git = "git",
}
-- install all plugins if they don't exist yet in plugins directory
function plugin.installall(plugins)
  local crs = {}
  local function install(specs)
    for name, spec in pairs(specs) do
      spec.name = name
      if not plugin.exists(spec) then
        if spec.requires then
          local missing = false
          local requiredplugins = {}
          for _, requiredname in ipairs(spec.requires) do
            local requiredspec = plugins[requiredname]
            if not requiredspec then
              core.log("Missing dependency '%s' for plugin '%s'", requiredname, name)
              missing = true
              goto nextrequired
            end
            requiredplugins[requiredname] = requiredspec
            ::nextrequired::
          end
          if missing then
            core.log("Plugin '%s' not installed due to missing dependencies", name)
            goto nextplugin
          end
          install(requiredplugins)
        end
        core.log("Installing plugin '%s'", name)
        local key = plugin.install(spec)
        local thread = core.threads[key]
        if thread then
          table.insert(crs, thread.cr)
        end
      end
      ::nextplugin::
    end
  end
  install(plugins)
  if #crs > 0 then
    core.add_thread(function()
      local running = true
      while running do
        running = false
        for _, cr in ipairs(crs) do
          if coroutine.status(cr) ~= "dead" then
            running = true
            goto nextcheck
          end
        end
        ::nextcheck::
        coroutine.yield(0.1)
      end
      core.log("All plugins installed, you may want to reload configuration.")
    end)
  end
end
-- create a plugin file/directory based on plugin specification
function plugin.path(spec)
  local dir = PLUGINSDIR
  if spec.targetdir then
    dir = USERDIR .. PATHSEP .. spec.targetdir
  end
  local path = dir .. PATHSEP .. spec.name
  if spec.type == plugin.type.raw then
    path = path .. ".lua"
  end
  return path
end
-- install single plugin
function plugin.install(spec)
  if spec.type == plugin.type.raw then
    return plugin.installraw(spec)
  elseif spec.type == plugin.type.git then
    return plugin.installgit(spec)
  end
end
function plugin.installwithcmd(spec, cmd)
  return core.add_thread(function()
    local name = spec.name

    core.log("Plugin '%s' install process starting...", name)

    local downloader = process.start(cmd)

    while downloader:running() do
      coroutine.yield(0.1)
    end

    local returncode = downloader:returncode()
    core.log("Plugin '%s' download process ended with result: %d", name, returncode)

    if returncode ~= 0 then
      core.log("Error occurred during downloading '%s' plugin: %s", name, downloader:read_stdout() or "")
      return
    end

    if spec.patch then
      plugin.patch(spec)
    end

    if spec.post then
      plugin.post(spec)
    end
  end)
end
-- install raw plugin (download single plugin file directly)
function plugin.installraw(spec)
  local targetfilename = plugin.path(spec)
  return plugin.installwithcmd(spec, {
      "sh", "-c",
      "curl --create-dirs -fLo " .. targetfilename .. " " .. spec.url
    })
end
-- install git-based plugin
function plugin.installgit(spec)
  local targetfilename = plugin.path(spec)
  local branch = spec.branch or "master"
  return plugin.installwithcmd(spec, {
    "sh", "-c",
    "git clone -b " .. branch .. " " .. spec.url .. " " .. targetfilename
  })
end
-- apply patch to plugin
function plugin.patch(spec)  -- requires installed patch
  core.log("Patching plugin '%s'", spec.name)
  local plugindir = plugin.dir(spec)
  local cmd = {
    "sh", "-c",
    "patch -p1 -ud " .. plugindir .. " -i " .. PATCHESDIR .. PATHSEP .. spec.patch
  }
  local patcher = process.start(cmd)

  while patcher:running() do
    coroutine.yield(0.02)
  end

  local returncode = patcher:returncode()
  if returncode == 0 then
    core.log("Patched plugin '%s'", spec.name)
  else
    core.log("Error occurred during patching plugin '%s': %s", spec.name, patcher:read_stderr() or "")
  end
end
-- apply post-install action to plugin
function plugin.post(spec)
  core.log("Running post-install actions for plugin '%s'", spec.name)
  local plugindir = plugin.dir(spec)
  local cmd = {
    "sh", "-c",
    spec.post,
  }
  local options = {
    cwd = plugindir,
  }

  local runner = process.start(cmd, options)

  while runner:running() do
    coroutine.yield(0.1)
  end

  local returncode = runner:returncode()
  if returncode == 0 then
    core.log("Post-install action for plugin '%s' applied successfully", spec.name)
  else
    core.log("Error occurred during running post-install actions for plugin '%s': %s",
      spec.name, runner:read_stderr() or "")
  end
end
-- get basedir of plugin
function plugin.dir(spec)
  if spec.type == plugin.type.raw then
    return PLUGINSDIR
  else
    return plugin.path(spec)
  end
end
-- check if plugin exists
function plugin.exists(spec)
  local targetfilename = plugin.path(spec)
  return system.get_file_info(targetfilename) ~= nil
end
function plugin.makecmd(...)
  local cmds = {}
  for _, arg in ipairs { ... } do
    if type(arg) == "table" then
      for _, cmd in ipairs(arg) do
        table.insert(cmds, cmd)
      end
    else
      table.insert(cmds, arg)
    end
  end
  return table.concat(cmds, " && ")
end
function plugin.withtmpdir(...)
  local cmds = {
    "cwd=$(pwd)",
    "tmpdir=$(mktemp --directory)",
    "cd $tmpdir",
  }
  for _, arg in ipairs { ... } do
    table.insert(cmds, arg)
  end
  table.insert(cmds, "cd $cwd")
  table.insert(cmds, "rm -rf $tmpdir")
  return cmds
end

-- user configuration part (plugins specification)
local luaversion = _VERSION:match("%d.%d")
local plugins = {
  autoinsert = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/autoinsert.lua",
  },
  autosaveonfocuslots = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/autosaveonfocuslost.lua",
  },
  bracketmatch = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/bracketmatch.lua",
  },
  colorpreview = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/colorpreview.lua",
  },
  console = {
    type = plugin.type.git,
    url = "https://github.com/lite-xl/console.git",
  },
  eofnewline = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/bokunodev/lite_modules/master/plugins/eofnewline-xl.lua",
    patch = "eofnewline.patch"
  },
  ephemeraltabs = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/ephemeral_tabs.lua",
  },
  evergreen = { -- requires luarocks (and setup), tree-sitter-devel, lua-devel
    type = plugin.type.git,
    url = "https://github.com/TorchedSammy/Evergreen.lxl.git",
    post = plugin.makecmd(
      plugin.withtmpdir(
        "luarocks --lua-version " .. luaversion .. " download --rockspec ltreesitter --dev",
        [[sed -i -E 's/^(.*sources.*)$/\1\n"csrc\/types.c",/' ltreesitter-dev-1.rockspec]],
        "luarocks --lua-version " .. luaversion .. " install --local ltreesitter-dev-1.rockspec"
      ),
      "ln -sf " .. os.getenv("HOME") .. "/.luarocks/lib/lua/" .. luaversion .. "/ltreesitter.so " .. USERDIR
    ),
    patch = "evergreen.patch",
  },
  fontconfig = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/fontconfig.lua",
  },
  lfautoinsert = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/lfautoinsert.lua",
    patch = "lfautoinsert.patch",
  },
  lsp = {
    type = plugin.type.git,
    url = "https://github.com/lite-xl/lite-xl-lsp.git",
    requires = {
      "lintplus", "lsp_snippets", "snippets", "widget"
    }
  },
  lintplus = {
    type = plugin.type.git,
    url = "https://github.com/liquidev/lintplus.git",
    patch = "lintplus.patch",
  },
  lsp_snippets = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/lsp_snippets.lua",
  },
  snippets = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/vqns/lite-xl-snippets/main/snippets.lua",
  },
  widget = {
    type = plugin.type.git,
    url = "https://github.com/lite-xl/lite-xl-widgets.git",
    targetdir = "libraries",
  },
  lspkind = {
    type = plugin.type.git,
    url = "https://github.com/TorchedSammy/lite-xl-lspkind.git",
    post = plugin.makecmd(
      plugin.withtmpdir(
        "curl -fLo Hack.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip",
        "unzip Hack.zip",
        "mkdir -p " .. FONTSDIR,
        "cp 'Hack Regular Nerd Font Complete Mono.ttf' " .. FONTSDIR
      ),
      "mv autocomplete.lua " .. PLUGINSDIR
    ),
  },
  navigate = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/navigate.lua",
  },
  nonicons = {
    type = plugin.type.raw,
    url = "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/nonicons.lua",
    post = "curl --create-dirs -fLo " .. FONTSDIR .. PATHSEP .. "nonicons.ttf https://github.com/yamatsum/nonicons/raw/6a2faf4fbdfbe353c5ae6a496740ac4bfb6d0e74/dist/nonicons.ttf",
  },
  scm = {
    type = plugin.type.git,
    url = "https://github.com/lite-xl/lite-xl-scm.git",
  }
}
plugin.installall(plugins)

------------------------ Plugin configuration ----------------------------------

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

local command = require "core.command"
local syntax = require "core.syntax"
command.add("core.docview!", {
  ["test:reset-highlight"] = function(dv)
    core.log('syntax: %s', syntax.get(dv.doc.filename).name)
    dv.doc.highlighter:reset()
  end
})

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

