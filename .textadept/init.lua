if not CURSES then
  view:set_theme('dark', { font = 'Hack', size = 14 })
end

-- XXX change for different languages, e.g. Lua
buffer.use_tabs = false
buffer.tab_width = 2
events.connect(events.LEXER_LOADED, function(name)
  if name == 'go' then
    buffer.use_tabs = true
  end
end)

textadept.editing.strip_trailing_spaces = true
