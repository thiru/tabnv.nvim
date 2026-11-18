--- Domain-agnostic helper functions.

local M = {}

function M.create_centred_float_win()
  local width = vim.o.columns * 0.8
  local height = vim.o.lines * 0.8
  local row = (vim.o.lines - height) / 2
  local col = (vim.o.columns - width) / 2

  local buf = vim.api.nvim_create_buf(false, true)
  local win = vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = math.floor(width),
    height = math.floor(height),
    row = math.floor(row),
    col = math.floor(col),
    style = 'minimal',
  })
  return win, buf
end

--- Create a nested Neovim instance with tabnv in terminal mode.
function M.new_float_term()
  local _, buf = M.create_centred_float_win()

  local job = vim.fn.jobstart({ 'nvim', '+TabnvStart' }, {
    term = true,
    on_exit = function()
      -- Remove the finished terminal buffer so its exit prompt is not shown.
      vim.schedule(function()
        if vim.api.nvim_buf_is_valid(buf) then
          pcall(vim.api.nvim_buf_delete, buf, { force = true })
        end
      end)
    end,
  })

  if job > 0 then
    vim.cmd.startinsert()
  end
end

return M
