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

return {
  defer = defer,
  apply = apply,
  nop = nop,
  get_pos = get_pos,
}
