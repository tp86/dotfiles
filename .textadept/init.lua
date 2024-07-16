require('cut.dynamic_theme').set()

require('cut.options')

require('cut.experimental').run(function()
  require('custom.keys')
end)

events.connect(events.LEXER_LOADED, function(lexer)
  pcall(require, 'lang.'..lexer)
end)
