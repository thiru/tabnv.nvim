local u = require('tabnv.utils')

local M = {}

function M.create_centred_float_win()
  local width = vim.o.columns * 0.8
  local height = vim.o.lines * 0.8
  local row = (vim.o.lines - height) / 2
  local col = (vim.o.columns - width) / 2

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_open_win(buf, true, {
    relative = 'editor',
    width = math.floor(width),
    height = math.floor(height),
    row = math.floor(row),
    col = math.floor(col),
    style = 'minimal',
  })
end

--- Create a nested Neovim instance with tabnv in terminal mode.
function M.new_float_term()
  M.create_centred_float_win()

  local job = vim.fn.jobstart({ "nvim", "+TabnvStart" }, { term = true })

  if job > 0 then
    vim.cmd.startinsert()
  end
end

return M
