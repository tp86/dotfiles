local core = require "core"
local keymap = require "core.keymap"

local originalkeymap = require "modal.keymap"
local modes = {}
local modal
modal = {
  map = function(mappings)
    for name, mapping in pairs(mappings) do
      if name ~= "default" then
        local map, mt = {}, {}
        for key, action in pairs(mapping) do
          -- TODO refactor
          if key ~= "fallback" then
            -- TODO support for multiple actions as in original keymap
            map[key] = { action }
          else
            local fallback
            if type(action) == "function" then
              fallback = action
            elseif type(action) == "table" then
              local keys = {}
              for _, key in ipairs(action) do
                keys[key] = true
              end
              fallback = function(key)
                return keys[key]
              end
            end
            mt.__index = function(_, key)
              if fallback(key) then
                return originalkeymap[key]
              end
              core.log(key .. " not mapped")
              return { function() return true end }
            end
          end
        end
        setmetatable(map, mt)
        for key in pairs(map) do
          core.log("%s: %s", name, key)
        end
        modes[name] = map
      end
    end
    modes.default = modes[mappings.default]
  end,
  mode = function(modename)
    return function()
      core.log("activating mode %s", modename)
      keymap.map = modes[modename]
    end
  end,
  activate = function()
    local viewmodifier = require "modal.view"
    viewmodifier.activate(function() modal.mode("default")() end, function() keymap.map = originalkeymap end)
  end,
}

return modal

