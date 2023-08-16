local core = require "core"
local command = require "core.command"
local doc = require "core.doc"
local save = doc.save
function doc:save(filename, abs_filename)
  -- automatically convert indentation to spaces on save
  command.perform "indent-convert:tabs-to-spaces"
  save(self, filename, abs_filename)
end

