-- inspired by https://github.com/meow-edit/meow

local DIR = {
  FORWARD = 'forward',
  BACKWARD = 'backward',
}
local TYPE = {
  CHAR = 'char',
  WORD = 'word',
  VISIT = 'visit',
}

-- default selection
local selection = {
  direction = DIR.FORWARD,
  type = TYPE.CHAR,
  extendable = false,
}

local function set_selection_type(type, extendable)
  selection.type = type or selection.type
  if extendable ~= nil then
    selection.extendable = extendable
  end
end

local function set_selection_direction(direction)
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

M.selection = setmetatable({}, {
  __index = selection,
  __newindex = function() end,
})

local function no_extend_char_move(direction, base_func_name)
  return function()
    set_selection_direction(direction)
    if selection.type == TYPE.CHAR and selection.extendable then
      buffer[base_func_name..'_extend'](buffer)
    else
      set_selection_type(TYPE.CHAR, false)
      buffer[base_func_name](buffer)
    end
  end
end

M.left = no_extend_char_move(DIR.BACKWARD, 'char_left')
M.right = no_extend_char_move(DIR.FORWARD, 'char_right')
M.prev = no_extend_char_move(DIR.BACKWARD, 'line_up')
M.next = no_extend_char_move(DIR.BACKWARD, 'line_down')

local function no_extend_word_move(direction, base_func_name)
  return function()
    set_selection_direction(direction)
    if selection.type == TYPE.WORD and selection.extendable then
      direct_selections(direction)
      buffer[base_func_name](buffer)
    else
      set_selection_type(TYPE.WORD, false)
      empty_selections()
      buffer[base_func_name](buffer)
    end
  end
end

M.next_word = no_extend_word_move(DIR.FORWARD, 'word_right_end_extend')
M.back_word = no_extend_word_move(DIR.BACKWARD, 'word_left_extend')

local function extend_char_move(direction, base_func_name)
  return function()
    set_selection_direction(direction)
    set_selection_type(TYPE.CHAR, true)
    buffer[base_func_name](buffer)
  end
end

M.left_extend = extend_char_move(DIR.BACKWARD, 'char_left_extend')
M.right_extend = extend_char_move(DIR.FORWARD, 'char_right_extend')
M.prev_extend = extend_char_move(DIR.BACKWARD, 'line_up_extend')
M.next_extend = extend_char_move(DIR.FORWARD, 'line_down_extend')

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

local function mark_word(direction, anchor_pos_func_name, caret_pos_func_name)
  -- for forward direction
  local anchor_pos_func_name = 'word_start_position'
  local caret_pos_func_name = 'word_end_position'
  local left_and_right_to_direction_classes = function(l, r)
    return r, l
  end
  -- swap for backward direction
  if direction == DIR.BACKWARD then
    anchor_pos_func_name, caret_pos_func_name = caret_pos_func_name, anchor_pos_func_name
    left_and_right_to_direction_classes = function(l, r)
      return l, r
    end
  end
  return function()
    set_selection_direction(direction)
    set_selection_type(TYPE.WORD, true)
    for n = 1, buffer.selections do
      local caret = buffer.selection_n_caret[n]
      local char_at_left = buffer.char_at[caret-1]
      local char_at_right = buffer.char_at[caret]
      local left_class, right_class = get_chars_classes(char_at_left, char_at_right)
      local dir_class, opposite_class = left_and_right_to_direction_classes(left_class, right_class)
      if dir_class == CHAR_CLASS.WHITESPACE then
        if opposite_class ~= CHAR_CLASS.WHITESPACE then
          local word_anchor = buffer[anchor_pos_func_name](buffer, caret, false)
          buffer.selection_n_anchor[n] = word_anchor
        end
        -- do nothing if both chars are whitespace
      -- char in the direction is not a whitespace
      elseif dir_class == opposite_class then
        local word_anchor = buffer[anchor_pos_func_name](buffer, caret, false)
        local word_caret = buffer[caret_pos_func_name](buffer, caret, false)
        buffer.selection_n_anchor[n] = word_anchor
        buffer.selection_n_caret[n] = word_caret
      else
        local word_caret = buffer[caret_pos_func_name](buffer, caret, false)
        buffer.selection_n_anchor[n] = caret
        buffer.selection_n_caret[n] = word_caret
      end
    end
    -- TODO handle pushing selected words to search ring
  end
end

M.mark_right_word = mark_word(DIR.FORWARD)
M.mark_left_word = mark_word(DIR.BACKWARD)

function M.reverse_direction()
  if selection.direction == DIR.FORWARD then
    set_selection_direction(DIR.BACKWARD)
  else
    set_selection_direction(DIR.FORWARD)
  end
  direct_selections(selection.direction)
end

local type_and_dir_to_expansion_func = setmetatable({
  [TYPE.CHAR] = {
    [DIR.BACKWARD] = M.left,
    [DIR.FORWARD] = M.right,
  },
  [TYPE.WORD] = {
    [DIR.BACKWARD] = M.back_word,
    [DIR.FORWARD] = M.next_word,
  }
}, {
  __index = function() end,
})

function M.expand_n(n)
  local move = type_and_dir_to_expansion_func[selection.type][selection.direction]
  for _ = 1, n do
    move()
  end
end

local last_search_text = ""

local function search()
  ui.print_silent(last_search_text)
  buffer:search_anchor()
  if selection.direction == DIR.FORWARD then
    buffer:search_next(buffer.FIND_REGEXP, last_search_text)
  else
    buffer:search_prev(buffer.FIND_REGEXP, last_search_text)
  end
  view:scroll_caret()
end

local function on_visit(text)
  last_search_text = text
  search()
end

function M.visit()
  set_selection_type(TYPE.VISIT, false)
  ui.command_entry.run('/', on_visit)
end

local function escape_regex(text)
  ui.print_silent(text)
  local escaped = {}
  for char in text:gmatch('.') do
    if char == '[' then
      table.insert(escaped, '\\')
    end
    table.insert(escaped, char)
  end
  return table.concat(escaped)
end

function M.search()
  set_selection_type(TYPE.VISIT, false)
  -- check if main selection matches last_search_text
  if not buffer.selection_empty then
    -- set target to be main selection
    buffer:target_from_selection()
    -- remember search_flags
    local search_flags = buffer.search_flags
    buffer.search_flags = buffer.FIND_REGEXP
    -- search for main selection text
    -- XXX debug
    if buffer:search_in_target(last_search_text) < 0 then
      last_search_text = escape_regex(buffer:text_range(buffer.target_start, buffer.target_end))
    end
    -- restore search flags
    buffer.search_flags = search_flags
  end
  search()
end

-- keys for testing
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
keys['alt+u'] = M.back_word
keys['alt+U'] = M.mark_left_word
keys['alt+0'] = function() M.expand_n(0) end
keys['alt+1'] = function() M.expand_n(1) end
keys['alt+2'] = function() M.expand_n(2) end
keys['alt+3'] = function() M.expand_n(3) end
keys['alt+4'] = function() M.expand_n(4) end
keys['alt+5'] = function() M.expand_n(5) end
keys['alt+6'] = function() M.expand_n(6) end
keys['alt+7'] = function() M.expand_n(7) end
keys['alt+8'] = function() M.expand_n(8) end
keys['alt+9'] = function() M.expand_n(9) end
keys['alt+-'] = M.reverse_direction
keys['alt+/'] = M.visit
keys['alt+n'] = M.search

return M
