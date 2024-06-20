local function nop() end

local function with(ctx, action)
  local ctx_value
  if type(ctx.enter) == 'function' then
    ctx_value = ctx.enter()
  end
  local results = table.pack(pcall(action, ctx_value))
  if type(ctx.exit) == 'function' then
    ctx.exit()
  end
  if results[1] then
    return select(2, table.unpack(results))
  else
    error(results[2], 2)
  end
end

return {
  nop = nop,
  with = with,
}
