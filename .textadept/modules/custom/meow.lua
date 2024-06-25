-- inspired by https://github.com/meow-edit/meow

local DIR = {
  FORWARD = 'forward',
  BACKWARD = 'backward',
}
local TYPE = {
  CHAR = 'char',
  WORD = 'word',
  LINE = 'line'
}

-- default selection
local selection = {
  direction = DIR.FORWARD,
  type = TYPE.CHAR,
  extendable = false,
}

local M = {}

function M.left()
  if selection.type == TYPE.CHAR and selection.extendable then
    buffer:char_left_extend()
  else
    selection.type = TYPE.CHAR
    selection.extendable = false
    buffer:char_left()
  end
end

function M.right()
  if selection.type == TYPE.CHAR and selection.extendable then
    buffer:char_right_extend()
  else
    selection.type = TYPE.CHAR
    selection.extendable = false
    buffer:char_right()
  end
end

function M.prev()
  if selection.type == TYPE.CHAR and selection.extendable then
    buffer:line_up_extend()
  else
    selection.type = TYPE.CHAR
    selection.extendable = false
    buffer:line_up()
  end
end

function M.next()
  if selection.type == TYPE.CHAR and selection.extendable then
    buffer:line_down_extend()
  else
    selection.type = TYPE.CHAR
    selection.extendable = false
    buffer:line_down()
  end
end

function M.left_extend()
  selection.extendable = true
  selection.type = TYPE.CHAR
  buffer:char_left_extend()
end

function M.right_extend()
  selection.extendable = true
  selection.type = TYPE.CHAR
  buffer:char_right_extend()
end

function M.prev_extend()
  selection.extendable = true
  selection.type = TYPE.CHAR
  buffer:line_up_extend()
end

function M.next_extend()
  selection.extendable = true
  selection.type = TYPE.CHAR
  buffer:line_down_extend()
end

function M.mark_word()
  selection.extendable = true
  selection.type = TYPE.WORD
  buffer:word_left()
  buffer:word_right_end_extend()
end

return M
