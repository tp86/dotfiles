local M = {}

M.insert_empty_lines = function(params)
    local current_pos = vim.fn.getcurpos()
    local new_pos = {current_pos[2], current_pos[5]}
    local line = new_pos[1]
    if params.above then
        line = new_pos[1] - 1
        new_pos[1] = new_pos[1] + params.count
    end
    vim.fn.append(line, vim.fn['repeat']({''}, params.count))
    vim.fn.cursor(new_pos)
end
return M
