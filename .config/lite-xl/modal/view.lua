local core = require "core"
local docview = require "core.docview"

local activated = false

local function activate(setfn, resetfn)
  if not activated then
    activated = true
    local set_active_view = core.set_active_view
    function core.set_active_view(view)
      set_active_view(view)
      if view:is(docview) then
        setfn()
      else
        resetfn()
      end
    end
  end
end

return {
  activate = activate,
}

