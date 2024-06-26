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

local function set_selection(type, extendable, direction)
  selection.type = type or selection.type
  if extendable ~= nil then
    selection.extendable = extendable
  end
  selection.direction = direction or selection.direction
end

local function empty_selections()
  for n = 1, buffer.selections do
    buffer.selection_n_anchor[n] = buffer.selection_n_caret[n]
  end
end

local function direct_selections(direction)
  for n = 1, buffer.selections do
    local anchor, caret = buffer.selection_n_anchor[n], buffer.selection_n_caret[n]
    if direction == DIR.FORWARD  and caret  < anchor
    or direction == DIR.BACKWARD and anchor < caret
    then
      buffer.selection_n_anchor[n], buffer.selection_n_caret[n] = caret, anchor
    end
  end
end

local M = {}

function M.left()
  if selection.type == TYPE.CHAR and selection.extendable then
    buffer:char_left_extend()
  else
    set_selection(TYPE.CHAR, false)
    buffer:char_left()
  end
end

function M.right()
  if selection.type == TYPE.CHAR and selection.extendable then
    buffer:char_right_extend()
  else
    set_selection(TYPE.CHAR, false)
    buffer:char_right()
  end
end

function M.prev()
  if selection.type == TYPE.CHAR and selection.extendable then
    buffer:line_up_extend()
  else
    set_selection(TYPE.CHAR, false)
    buffer:line_up()
  end
end

function M.next()
  if selection.type == TYPE.CHAR and selection.extendable then
    buffer:line_down_extend()
  else
    set_selection(TYPE.CHAR, false)
    buffer:line_down()
  end
end

function M.next_word()
  if selection.type == TYPE.WORD and selection.extendable then
    direct_selections(DIR.FORWARD)
    buffer:word_right_end_extend()
  else
    set_selection(TYPE.WORD, false)
    empty_selections()
    buffer:word_right_end_extend()
  end
end

function M.left_extend()
  set_selection(TYPE.CHAR, true)
  buffer:char_left_extend()
end

function M.right_extend()
  set_selection(TYPE.CHAR, true)
  buffer:char_right_extend()
end

function M.prev_extend()
  set_selection(TYPE.CHAR, true)
  buffer:line_up_extend()
end

function M.next_extend()
  set_selection(TYPE.CHAR, true)
  buffer:line_down_extend()
end

local CHAR_CLASS = {
  WORD = "word",
  PUNCTUATION = "punctuation",
  WHITESPACE = "whitespace",
}

local magic_chars = {
  ['^'] = true,
  ['$'] = true,
  ['('] = true,
  [')'] = true,
  ['%'] = true,
  ['.'] = true,
  ['['] = true,
  [']'] = true,
  ['*'] = true,
  ['+'] = true,
  ['-'] = true,
  ['?'] = true,
}
local function escape_pattern_char(char)
  if magic_chars[char] then char = '%' .. char end
  return char
end

local function get_chars_classes(...)
  local classes = {}
  for _, char in ipairs{...} do
    local class
    local char = escape_pattern_char(string.char(char))
    if buffer.word_chars:match(char) then
      class = CHAR_CLASS.WORD
    elseif buffer.punctuation_chars:match(char) then
      class = CHAR_CLASS.PUNCTUATION
    elseif (buffer.whitespace_chars .. "\r\n"):match(char) then
      class = CHAR_CLASS.WHITESPACE
    end
    table.insert(classes, class)
  end
  return table.unpack(classes)
end

function M.mark_right_word()
  set_selection(TYPE.WORD, true)
  for n = 1, buffer.selections do
    local caret = buffer.selection_n_caret[n]
    local char_at_left = buffer.char_at[caret-1]
    local char_at_right = buffer.char_at[caret]
    local left_class, right_class = get_chars_classes(char_at_left, char_at_right)
    if right_class == CHAR_CLASS.WHITESPACE then
      if left_class ~= CHAR_CLASS.WHITESPACE then
        local word_start = buffer:word_start_position(caret, false)
        buffer.selection_n_anchor[n] = word_start
      end
      -- do nothing if both chars are whitespace
    -- right char is not a whitespace
    elseif left_class == right_class then
      local word_start = buffer:word_start_position(caret, false)
      local word_end = buffer:word_end_position(caret, false)
      buffer.selection_n_anchor[n] = word_start
      buffer.selection_n_caret[n] = word_end
    else
      local word_end = buffer:word_end_position(caret, false)
      buffer.selection_n_anchor[n] = caret
      buffer.selection_n_caret[n] = word_end
    end
  end
end

keys['alt+i'] = M.prev
keys['alt+I'] = M.prev_extend
keys['alt+k'] = M.next
keys['alt+K'] = M.next_extend
keys['alt+j'] = M.left
keys['alt+J'] = M.left_extend
keys['alt+l'] = M.right
keys['alt+L'] = M.right_extend
keys['alt+o'] = M.next_word
keys['alt+O'] = M.mark_right_word

return M
