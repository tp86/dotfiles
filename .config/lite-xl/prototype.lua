local prototype = {}

function prototype:new(o)
  o = o or {}
  self.__index = self
  return setmetatable(o, self)
end

return prototype

