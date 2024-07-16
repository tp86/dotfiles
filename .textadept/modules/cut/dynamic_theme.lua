local themes = {
  light = {'light', { font = 'Hack', size = 14 }},
  dark =  {'dark',  { font = 'Hack', size = 14 }},
}

local hours = {
  light = 8,
  dark = 19,
}

local function set_theme()
  local hour = os.date('*t').hour
  local theme = themes.light
  if hour < hours.light or hour >= hours.dark then
    theme = themes.dark
  end
  -- TODO set different themes per view
  -- here or in another plugin
  for _, view in ipairs(_VIEWS) do
    view:set_theme(table.unpack(theme))
  end
  if type(ui.command_entry.set_theme) == 'function' then
    ui.command_entry:set_theme(table.unpack(theme))
  end
end

local function set()
  if not CURSES then
    -- run immediately...
    set_theme()
    -- ...and every 30 minutes
    timeout(30*60, function()
      set_theme()
      return true
    end)
  end
end

return {
  themes = themes,
  hours = hours,
  set = set,
}
