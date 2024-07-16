local function connect_events(event_names, action)
  for _, event in ipairs(event_names) do
    events.connect(event, action)
  end
end

return {
  connect_events = connect_events,
}
