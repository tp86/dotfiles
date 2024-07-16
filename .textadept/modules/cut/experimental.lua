local event = 'cut.experimental'

local function setup()
  events.emit(event)
  events.connect(events.RESET_BEFORE, function(persist)
    persist.experimental = true
  end)
end

args.register('-E', '--experimental', 0, setup, "Enable experimental code")

local function set_action(action)
  events.connect(event, action)
  events.connect(events.RESET_AFTER, function(persist)
    if persist.experimental then action() end
  end)
end

return {
  run = set_action,
}
