-- Plugin installer inspired by lixling, but focused mostly on
-- installing missing plugins on startup and easy applying patches

-- Usage example:
-- local plugininstaller = require "plugininstaller"
-- local raw, git = plugininstaller.type.raw, plugininstaller.type.git
-- local plugins = {
--   -- download single plugin file
--   fontconfig = raw"https://raw.githubusercontent.com/lite-xl/lite-xl-plugins/master/plugins/fontconfig.lua",
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

plugininstaller.type = {}
function plugininstaller.type.raw(url)
  return {
    type = types.raw,
    url = url,
  }
end
function plugininstaller.type.git(url)
  return {
    type = types.git,
    url = url,
  }
end

local function gettargetpath(pluginspec)
  local targetpath = PLUGINSDIR
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
  local spec = {
    name = name,
    type = options.type,
    url = options.url,
    patch = options.patch,
    run = options.run,
    branch = options.branch,
  }
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
            local requiredspec = pluginspecs[requiredname]
            if requiredspec then
              table.insert(requiredpluginspecs, requiredspec)
            else
              core.warn("Missing dependency '%s' for plugin '%s'", requiredname, name)
              missing = true
            end
            if missing then
              core.warn("Plugin '%s' not installed due to missing dependencies", name)
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
function plugininstaller.utils.makecmd(...)
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

-- helper function for making command running inside temporary directory
-- current working directory is restored at end
-- does not support nesting
function plugininstaller.utils.withtmpdir(...)
  local cmds = {
    "cwd=$(pwd)",
    "tmpdir=$(mktemp --directory)",
    "cd $tmpdir",
    "cd $cwd",
    "rm -fr $tmpdir",
  }
  for _, arg in ipairs { ... } do
    table.insert(cmds, #cmds - 1, arg)
  end
  return cmds
end

return plugininstaller

