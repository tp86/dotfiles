-- Plugin installer inspired by lixling, but focused mostly on
-- installing missing plugins on startup and easy applying patches

-- Usage example:
-- local plugininstaller = require "plugininstaller"
-- local raw, git = plugininstaller.type.raw, plugininstaller.type.git
-- local plugins = {
--   -- download single plugin file
--   fontconfig = raw"https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/fontconfig.lua",
--   -- download git repository plugin
--   console = git "https://github.com/lite-xl/console.git",
--   -- single plugin file with patch
--   eofnewline = raw {
--     "https://raw.githubusercontent.com/bokunodev/lite_modules/master/plugins/eofnewline-xl.lua",
--     patch = "eofnewline.patch",
--   },
--   -- plugin with requirements
--   lsp = git {
--     "https://github.com/lite-xl/lite-xl-lsp.git",
--     requires = {
--       "lintplus", "lsp_snippets", "snippets", "widget"
--     },
--   },
--   -- single plugin with post-install run action
--   nonicons = raw {
--     "https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/nonicons.lua",
--     run = ("curl --create-dirs -fLo %s %s")
--       :format(FONTSDIR .. PATHSEP .. "nonicons.ttf",
--       "https://github.com/yamatsum/nonicons/raw/6a2faf4fbdfbe353c5ae6a496740ac4bfb6d0e74/dist/nonicons.ttf"),
--   },
--   -- with utils in post-install run action
--   lspkind = git {
--     "https://github.com/TorchedSammy/lite-xl-lspkind.git",
--     run = cmd(
--       withtmpdir(
--         "curl -fLo Hack.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v2.3.3/Hack.zip",
--         "unzip Hack.zip",
--         "mkdir -p " .. FONTSDIR,
--         "cp 'Hack Regular Nerd Font Complete Mono.ttf' " .. FONTSDIR
--       ),
--       "mv autocomplete.lua " .. PLUGINSDIR
--     ),
--   },
-- }
-- plugininstaller.install(plugins)

local core = require "core"

local plugininstaller = {}

-- supported types of plugins
-- raw - plugins as single file
-- git - plugin as git repository
local types = {
  raw = "raw",
  git = "git",
}

plugininstaller.type = setmetatable({}, {
  __index = function(_, k)
    if not types[k] then error("Unsupported plugin type " .. k) end
    return function(config)
      if type(config) == "string" then
        config = { config }
      end
      return {
        type = types[k],
        url = config[1],
        patch = config.patch,
        run = config.run,
        requires = config.requires,
        targetdir = config.targetdir,
        branch = config.branch,
      }
    end
  end
})

local function gettargetpath(pluginspec)
  local targetpath = PLUGINSDIR
  if pluginspec.targetdir then
    targetpath = USERDIR .. PATHSEP .. pluginspec.targetdir
  end
  targetpath = targetpath .. PATHSEP .. pluginspec.name
  if pluginspec.type == types.raw then
    targetpath = targetpath .. ".lua"
  end
  return targetpath
end

local function getplugindir(pluginspec)
  if pluginspec.type == types.raw then
    return PLUGINSDIR
  elseif pluginspec.type == types.git then
    return pluginspec.targetpath
  end
end

local function exists(pluginspec)
  return system.get_file_info(pluginspec.targetpath) ~= nil
end

local function makedownloadcommand(pluginspec)
  local command
  if pluginspec.type == types.raw then
    command = ("curl --create-dirs -fLo %s %s")
        :format(pluginspec.targetpath, pluginspec.url)
  elseif pluginspec.type == types.git then
    command = ("git clone -b %s %s %s")
        :format(pluginspec.branch or "master", pluginspec.url, pluginspec.targetpath)
  end
  return function() return command end
end

local function makepatchcommand(pluginspec)
  local command
  if pluginspec.patch then
    local plugindir = getplugindir(pluginspec)
    command = ("patch -p1 -ud %s -i %s")
        :format(plugindir, PATCHESDIR .. PATHSEP .. pluginspec.patch)
  end
  return function() return command end
end

local function makeruncommand(pluginspec)
  local command, options
  if pluginspec.run then
    local plugindir = getplugindir(pluginspec)
    command = pluginspec.run
    options = {
      cwd = plugindir
    }
  end
  return function() return command, options end
end

local function makecommands(pluginspec)
  return {
    download = makedownloadcommand(pluginspec),
    patch = makepatchcommand(pluginspec),
    run = makeruncommand(pluginspec),
  }
end

local function makepluginspec(name, options)
  local spec = {}
  for k, v in pairs(options) do
    spec[k] = v
  end
  spec.name = name
  spec.targetpath = gettargetpath(spec)
  spec.commands = makecommands(spec)
  return spec
end

local function makepluginspecs(pluginsconfig)
  local specs = {}
  for name, options in pairs(pluginsconfig) do
    table.insert(specs, makepluginspec(name, options))
  end
  return specs
end

local function runprocess(processname, pluginspec)
  local command, options = pluginspec.commands[processname]()
  if not command then return end
  local name = pluginspec.name
  core.log_quiet("Running %s process for plugin '%s'", processname, name)

  local cmd = { "sh", "-c", command }

  local runner = process.start(cmd, options or {})

  while runner:running() do
    coroutine.yield(0.1)
  end

  local returncode = runner:returncode()
  local capitalizedprocessname = processname:gsub("^%a", string.upper)
  if returncode == 0 then
    core.log_quiet("%s process for plugin '%s' ended successfully.",
      capitalizedprocessname, name)
  else
    core.warn("%s process for plugin '%s' ended with failure. Return code: %d, error log: '%s'",
      capitalizedprocessname, name, returncode, runner:read_stderr() or "")
  end
end

local function install(pluginspec)
  -- prevent double installation due to race condition
  if pluginspec.handled then return end
  pluginspec.handled = true
  core.log("Installing plugin '%s'", pluginspec.name)
  return core.add_thread(function()
    runprocess("download", pluginspec)
    runprocess("patch", pluginspec)
    runprocess("run", pluginspec)
  end)
end

function plugininstaller.install(pluginsconfig)
  local pluginspecs = makepluginspecs(pluginsconfig)

  -- store plugin installation coroutines
  local crs = {}

  -- install given list of plugins specs
  local function installspecs(specs)
    for _, pluginspec in ipairs(specs) do
      -- only install plugin if it does not yet exist
      if not exists(pluginspec) then
        -- check if plugin has dependencies
        if pluginspec.requires then
          -- is any required plugin missing from given config?
          -- note that it does not check if such plugin exists
          local missing = false
          local requiredpluginspecs = {}
          for _, requiredname in ipairs(pluginspec.requires) do
            -- search for required plugin in all plugins, not only current subset
            local requiredspec
            for _, pluginspec in ipairs(pluginspecs) do
              if pluginspec.name == requiredname then
                requiredspec = pluginspec
                break
              end
            end
            if requiredspec then
              table.insert(requiredpluginspecs, requiredspec)
            else
              core.warn("Missing dependency '%s' for plugin '%s'", requiredname, pluginspec.name)
              missing = true
            end
            if missing then
              core.warn("Plugin '%s' not installed due to missing dependencies", pluginspec.name)
              goto nextplugin
            end
          end
          -- install only required plugins first (recursively)
          installspecs(requiredpluginspecs)
        end
        local threadkey = install(pluginspec)
        local thread = core.threads[threadkey]
        if thread then
          table.insert(crs, thread.cr)
        end
      end
      ::nextplugin::
    end
  end

  -- install all plugins
  installspecs(pluginspecs)

  -- wait for plugin installations, if there are any
  if #crs > 0 then
    core.add_thread(function()
      local finished = false
      repeat
        finished = true
        for _, cr in ipairs(crs) do
          if coroutine.status(cr) ~= "dead" then
            -- there are still running installations
            finished = false
            break
          end
        end
        coroutine.yield(0.1)
      until finished
      core.log("All plugins installed, you may want to reload configuration.")
    end)
  end
end

plugininstaller.utils = {}

-- helper function for making single command from (possibly nested) list of commands
function plugininstaller.utils.makecmd(commands)
  local cmds = {}
  for _, command in ipairs(commands) do
    if type(command) == "table" then
      for _, cmd in ipairs(command) do
        table.insert(cmds, cmd)
      end
    else
      table.insert(cmds, command)
    end
  end
  return table.concat(cmds, " && ")
end

-- helper function for making command running inside temporary directory
-- current working directory is restored at end
-- does not support nesting
function plugininstaller.utils.withtmpdir(commands)
  local cmds = {
    "cwd=$(pwd)",
    "tmpdir=$(mktemp --directory)",
    "cd $tmpdir",
    "cd $cwd",
    "rm -fr $tmpdir",
  }
  for _, command in ipairs(commands) do
    table.insert(cmds, #cmds - 1, command)
  end
  return cmds
end

return plugininstaller

