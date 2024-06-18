local FOCUS = {}

local focus = ui.command_entry.focus
ui.command_entry.focus = function()
  focus()
  events.emit(FOCUS, ui.command_entry.active)
end

return {
  events = {
    FOCUS = FOCUS,
  }
}
