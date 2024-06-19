local function defer(f)
  return function(...)
    local args = table.pack(...)
    return function()
      return f(table.unpack(args))
    end
  end
end

local function apply(f, ...)
  return defer(f)(...)
end

local function nop() end

local function get_pos()
  local pos = buffer.current_pos
  local line = buffer:line_from_position(pos)
  local col = buffer.column[pos]
  return line, col, pos
end

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
  defer = defer,
  apply = apply,
  nop = nop,
  get_pos = get_pos,
  with = with,
}
