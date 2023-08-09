local core = require "core"
local keymap = require "core.keymap"

local originalkeymap = require "modal.keymap"
local viewmodifier = require "modal.view"

local modes = {}

local function nop() end

local function setupfallback(mt, fallbackkeys)
  local fallback
  if type(fallbackkeys) == "function" then
    fallback = fallbackkeys
  elseif type(fallbackkeys) == "table" then
    -- convert sequence of keys into lookup table
    local keys = {}
    for _, key in ipairs(fallbackkeys) do
      keys[key] = true
    end
    fallback = function(key)
      return keys[key]
    end
  end
  mt.__index = function(_, key)
    if fallback(key) then
      return originalkeymap.map[key]
    end
    core.log(key .. " not mapped")
    return { nop }
  end
end

local function restore(maponly)
  keymap.map = originalkeymap.map
  if not maponly then
    keymap.reverse_map = originalkeymap.reverse_map
  end
end

local function createmaps(keys, mt)
  keymap.map, keymap.reverse_map = {}, {}
  originalkeymap.add_direct(keys)
  local map, reverse_map = keymap.map, keymap.reverse_map
  restore()
  setmetatable(map, mt)
  return map, reverse_map
end

local modal = {}

function modal.map(modemaps)
  for name, modemap in pairs(modemaps) do
    local keys, mt = {}, {}
    for key, actions in pairs(modemap) do
      if key == "fallback" then
        setupfallback(mt, actions)
      else
        keys[key] = actions
      end
    end
    local map, reversemap = createmaps(keys, mt)
    modes[name] = {
      map = map,
      reversemap = reversemap,
    }
  end
end

function modal.mode(modename)
  return function()
    --core.log("activating mode %s", modename)
    keymap.map = modes[modename].map
    keymap.reverse_map = modes[modename].reversemap
  end
end

function modal.activate(modename)
  viewmodifier.activate(modal.mode(modename), restore)
  -- keymap.add = nop
  -- keymap.add_direct = nop
end

return modal

