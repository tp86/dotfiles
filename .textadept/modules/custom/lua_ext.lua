-- based on https://leafo.net/guides/setfenv-in-lua52-and-above.html
-- override **some** of global variables in f's _ENV
-- example usage:
--[[
function test()
  ui.print('test')
end

test = with_globals(test, {
  ui = setmetatable({
    print = function(msg) ui.print(msg .. ' overriden') end,
  }, {
    __index=ui,
  })
})

test() -- will print 'test overriden'
]]
local function with_globals(f, env)
  local fenv
  local i = 1

  -- search for _ENV upvalue
  while true do
    local name, val = debug.getupvalue(f, i)
    if not name then break end
    if name == '_ENV' then
      fenv = val
      break
    end
    i = i + 1
  end
  -- now we have i pointing to index of _ENV in f's upvalues
  -- and fenv pointing to original _ENV
  if fenv then -- override only if we actually found _ENV in upvalues
    local env = setmetatable(env, {__index = fenv})
    debug.upvaluejoin(f, i, function() return env end, 1)
  end
  return f
end

local function table_overrides(tbl, overrides)
  return setmetatable(overrides, { __index = tbl, __newindex = {} })
end

return {
  with_globals = with_globals,
  table_overrides = table_overrides,
}
