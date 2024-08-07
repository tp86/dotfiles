-- inspired by https://github.com/meow-edit/meow

-- TODO refactor

local DIR = {
  FORWARD = 'forward',
  BACKWARD = 'backward',
}
local TYPE = {
  CHAR = 'char',
  CHAR_LINE = 'char_line',
  WORD = 'word',
  VISIT = 'visit',
  LINE = 'line',
  BLOCK = 'block',
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

local function set_default_selection()
  set_selection_type(TYPE.CHAR, false)
  set_selection_direction(DIR.FORWARD)
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

function M.empty_selections()
  for n = 1, buffer.selections do
    buffer.selection_n_anchor[n] = buffer.selection_n_caret[n]
  end
  set_selection_type(selection.type, false)
end

M.selection = setmetatable({}, {
  __index = selection,
  __newindex = function() end,
})

local function no_extend_char_move(direction, base_func_name, line)
  return function()
    set_selection_direction(direction)
    if (selection.type == TYPE.CHAR or selection.type == TYPE.CHAR_LINE) and selection.extendable then
      buffer[base_func_name..'_extend'](buffer)
    else
      local type = TYPE.CHAR
      if line then
        type = TYPE.CHAR_LINE
      end
      set_selection_type(type, false)
      buffer[base_func_name](buffer)
    end
  end
end

M.left = no_extend_char_move(DIR.BACKWARD, 'char_left')
M.right = no_extend_char_move(DIR.FORWARD, 'char_right')
M.prev = no_extend_char_move(DIR.BACKWARD, 'line_up', true)
M.next = no_extend_char_move(DIR.FORWARD, 'line_down', true)

local function no_extend_word_move(direction, base_func_name)
  return function()
    set_selection_direction(direction)
    if selection.type == TYPE.WORD and selection.extendable then
      direct_selections(direction)
      buffer[base_func_name](buffer)
    else
      set_selection_type(TYPE.WORD, false)
      M.empty_selections()
      buffer[base_func_name](buffer)
    end
  end
end

M.next_word = no_extend_word_move(DIR.FORWARD, 'word_right_end_extend')
M.back_word = no_extend_word_move(DIR.BACKWARD, 'word_left_extend')

local function extend_char_move(direction, base_func_name, line)
  return function()
    set_selection_direction(direction)
    local type = TYPE.CHAR
    if line then
      type = TYPE.CHAR_LINE
    end
    set_selection_type(type, true)
    buffer[base_func_name](buffer)
  end
end

M.left_extend = extend_char_move(DIR.BACKWARD, 'char_left_extend')
M.right_extend = extend_char_move(DIR.FORWARD, 'char_right_extend')
M.prev_extend = extend_char_move(DIR.BACKWARD, 'line_up_extend', true)
M.next_extend = extend_char_move(DIR.FORWARD, 'line_down_extend', true)

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
  [TYPE.CHAR_LINE] = {
    [DIR.BACKWARD] = M.prev,
    [DIR.FORWARD] = M.next,
  },
  [TYPE.WORD] = {
    [DIR.BACKWARD] = M.back_word,
    [DIR.FORWARD] = M.next_word,
  },
  [TYPE.LINE] = {
    [DIR.BACKWARD] = function() M.line() end,
    [DIR.FORWARD] = function() M.line() end,
  },
  [TYPE.BLOCK] = {
    [DIR.BACKWARD] = function() M.block() end,
    [DIR.FORWARD] = function() M.block() end,
  },
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

local function simple_search()
  -- TODO wrap around
  buffer.search_flags = buffer.FIND_REGEXP
  if selection.direction == DIR.FORWARD then
    buffer:set_target_range(buffer.current_pos, buffer.length + 1)
  else
    buffer:set_target_range(buffer.current_pos, 1)
  end
  local newlines = {
    ['\\n'] = true,
  }
  local split_positions = {}
  local s, e = 0, 0
  repeat
    for eol in pairs(newlines) do
      s, e = last_search_text:find(eol, s + (e - s))
      if s then
        table.insert(split_positions, {s, e})
        break
      end
    end
  until not s
  ui.print_silent(#split_positions)
  if #split_positions > 0 then
    local lst_s = 1
    for _, pos in ipairs(split_positions) do
      if buffer:search_in_target(last_search_text:sub(lst_s, pos[1] - 1)) >= 0 then

      end
    end

    buffer.search_flags = 0
    last_search_text = '\n'
    ui.print_silent('newline found')
  end
  if buffer:search_in_target(last_search_text) < 0 then return end
  local main_selection = buffer.main_selection
  buffer.selection_n_start[main_selection] = buffer.target_start
  buffer.selection_n_end[main_selection] = buffer.target_end
  direct_selections(selection.direction)
  view:scroll_caret()
end

local function search_in_selections()
  -- remember all selections
  local selections = {}
  for n = 1, buffer.selections do
    selections[n] = {
      buffer.selection_n_start[n],
      buffer.selection_n_end[n],
    }
  end
  local main_selection = {
    buffer.selection_n_start[buffer.main_selection],
    buffer.selection_n_end[buffer.main_selection],
  }
  buffer.search_flags = buffer.FIND_REGEXP
  -- perform search in each selection
  local matches = {}
  for _, selection in ipairs(selections) do
    local target_start, target_end = selection[1], selection[2]
    while true do
      buffer:set_target_range(target_start, target_end)
      if buffer:search_in_target(last_search_text) < 0 then break end
      -- search_in_target sets target range, use new values in next search
      target_start = buffer.target_end -- search for next occurence after found one
      target_end = selection[2] -- search until end of selection
      -- remember match
      table.insert(matches, {
        buffer.target_start,
        buffer.target_end,
      })
    end
  end
  -- select all matches
  if matches[1] then
    buffer:set_selection(matches[1][2], matches[1][1])
  end
  for n = 2, #matches do
    local match = matches[n]
    buffer:add_selection(match[2], match[1])
  end
  -- find match closest to original main selection
  -- TODO prefer matches in main selection
  -- TODO take selection.direction into account
  local distance = math.huge
  local closest_match
  for n, match in ipairs(matches) do
    local match_distance = math.abs(match[1] - main_selection[1])
    if match_distance < distance then
      distance = match_distance
      closest_match = n
    end
  end
  if closest_match then
    buffer.main_selection = closest_match
  end
  direct_selections(selection.direction)
  view:scroll_caret()
end

local function on_visit(text)
  last_search_text = text
  if buffer.selection_empty then
    simple_search()
  else
    search_in_selections()
  end
end

function M.visit()
  set_selection_type(TYPE.VISIT, false)
  ui.command_entry.run('/', on_visit)
end

local regex_magic_chars = {
  ['.'] = true,
  ['['] = true,
  [']'] = true,
  ['\\'] = true,
  ['*'] = true,
  ['+'] = true,
  ['?'] = true,
  ['{'] = true,
  ['}'] = true,
  ['|'] = true,
  ['^'] = true,
  ['$'] = true,
  ['('] = true,
  [')'] = true,
}
local function escape_regex(text)
  local escaped = {}
  for char in text:gmatch('.') do
    if regex_magic_chars[char] then
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
    buffer.search_flags = buffer.FIND_REGEXP
    -- search for main selection text
    if last_search_text == "" or buffer:search_in_target(last_search_text) < 0 then
      last_search_text = escape_regex(buffer:text_range(buffer.target_start, buffer.target_end))
    end
  end
  simple_search()
end

function M.line()
  -- select lines forward unless type is LINE and direction is BACKWARD
  if not (selection.type == TYPE.LINE and selection.direction == DIR.BACKWARD)
  then
    set_selection_direction(DIR.FORWARD)
  end
  set_selection_type(TYPE.LINE, true)
  local selections_lines = {}
  local select_whole_line
  for n = 1, buffer.selections do
    local selection_lines = {}
    local sel_start, sel_end = buffer.selection_n_start[n], buffer.selection_n_end[n]
    local sel_start_line, sel_end_line = buffer:line_from_position(sel_start), buffer:line_from_position(sel_end)
    local sel_start_line_start, sel_end_line_end = buffer:position_from_line(sel_start_line), buffer.line_end_position[sel_end_line]
    selection_lines = {
      sel_start = sel_start,
      sel_end = sel_end,
      start_line = sel_start_line,
      end_line = sel_end_line,
      line_start = sel_start_line_start,
      line_end = sel_end_line_end,
    }
    if sel_start > sel_start_line_start or sel_end < sel_end_line_end then
      select_whole_line = true
      selection_lines.select_whole = true
    end
    selections_lines[n] = selection_lines
  end
  if select_whole_line then
    for n = 1, buffer.selections do
      local selection_lines = selections_lines[n]
      if selection_lines.select_whole then
        buffer.selection_n_start[n] = selection_lines.line_start
        buffer.selection_n_end[n] = selection_lines.line_end
      end
    end
  else
    for n = 1, buffer.selections do
      local selection_lines = selections_lines[n]
      if selection.direction == DIR.FORWARD then
        buffer.selection_n_end[n] = buffer.line_end_position[selection_lines.end_line+1]
      else
        buffer.selection_n_start[n] = buffer:position_from_line(selection_lines.start_line-1)
        buffer.selection_n_end[n] = selection_lines.sel_end -- ensure that selection end stay the same
      end
    end
  end
  direct_selections(selection.direction)
end

-- TODO select between matching autopairs handling nested matches
-- for each selection, find closest matching pair that encloses selection's caret
function M.in_block()
  for n = 1, buffer.selections do
    -- based on textadept.editing.select_enclosed
    local caret = buffer.selection_n_caret[n]
    local caret_style = buffer.style_at[caret]
    local style_changed
    local pos = caret - 1
    while pos >= 1 do
      local char = string.char(buffer.char_at[pos])
      local pos_style = buffer.style_at[pos]
      style_changed = style_changed or (
        not buffer:name_of_style(pos_style):match('^whitespace')
        and pos_style ~= caret_style)
      local match_char = textadept.editing.auto_pairs[char]
      if match_char then
        local match_pos = buffer:brace_match(pos, 0)
        if match_pos < 0 then -- handle non-braces pairs
          if not style_changed then
            buffer.search_flags = 0
            buffer:set_target_range(pos + 1, buffer.length + 1)
            match_pos = buffer:search_in_target(match_char)
            -- TODO handle escaped string characters
          end
        end
        if match_pos >= caret then
          local anchor = buffer.selection_n_anchor[n]
          if anchor > match_pos then
            buffer.selection_n_caret[n] = pos + 1
          else
            buffer.selection_n_caret[n] = match_pos
          end
          if not (selection.type == TYPE.BLOCK and selection.extendable) or (anchor > pos and anchor <= match_pos) then
            buffer.selection_n_anchor[n] = pos + 1
          end
          break
        end
      end
      pos = pos - 1
    end
  end
  set_selection_type(TYPE.BLOCK, true)
  direct_selections(selection.direction)
end

-- TODO go to closest beginning/end of block in current selection direction
function M.to_block_start()

end

function M.cancel()
  if buffer.selection_empty then
    buffer:set_selection(buffer.current_pos, buffer.current_pos)
    set_default_selection()
  else
    M.empty_selections()
  end
end

return M
