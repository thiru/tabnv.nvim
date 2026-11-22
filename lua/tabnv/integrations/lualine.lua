--- Optional Lualine preset for tabnv.
---
--- This module is only loaded when explicitly required, so Lualine remains an optional dependency.

local M = {}

local function is_non_terminal_buffer()
  return vim.bo.buftype ~= 'terminal'
end

local function replace_home_with_tilde(path)
  local home = vim.uv.os_homedir()
  local next_char = home and path:sub(#home + 1, #home + 1)
  local is_home_path = home
    and (path == home or (path:sub(1, #home) == home and (next_char == '/' or next_char == '\\')))
  if is_home_path then
    return '~' .. path:sub(#home + 1)
  end
  return path
end

local function cwd()
  return replace_home_with_tilde(vim.fn.getcwd())
end

local function file_parent()
  local path = vim.api.nvim_buf_get_name(0)
  if path == '' then
    return ''
  end

  local relative_path = vim.fn.fnamemodify(path, ':.')
  local parent = vim.fs.dirname(relative_path)
  if parent == '.' or parent == '' then
    return ''
  end

  return replace_home_with_tilde(parent) .. '/'
end

local function buffer_location()
  if vim.fn.mode():find('t') then
    return ''
  end

  return '%{printf("%d:%d|%d%%", line("."), col("."), float2nr(100.0 * line(".") / line("$")))}'
end

local defaults = {
  options = {
    always_show_tabline = false,
    disabled_filetypes = {
      winbar = { 'aerial', 'DiffviewFileHistory' },
    },
    icons_enabled = true,
    component_separators = '',
    globalstatus = true,
    section_separators = '',
  },
  tabline = {
    lualine_a = {
      require('tabnv.workspace').tabline_workspaces,
    },
    lualine_b = {
      { require('tabnv.workspace').get_active_workspace_name, separator = { right = '' } },
    },
    lualine_z = {
      { require('tabnv.workspace').tabline_tabs, padding = { left = 0, right = 0 } },
    },
  },
  winbar = {
    lualine_c = {
      {
        'buffers',
        cond = is_non_terminal_buffer,
        symbols = {
          alternate_file = '',
        },
      },
    },
  },
  inactive_winbar = {
    lualine_c = {
      { 'filename', cond = is_non_terminal_buffer, path = 0 },
    },
  },
  sections = {
    lualine_a = {
      cwd,
      { file_parent, cond = is_non_terminal_buffer, color = 'Directory' },
    },
    lualine_b = {},
    lualine_c = {},
    lualine_x = {
      'selectioncount',
      'searchcount',
    },
    lualine_y = {
      { buffer_location, color = 'Directory' },
    },
    lualine_z = {
      { 'branch', color = 'ErrorMsg' },
    },
  },
}

local function is_list(tbl)
  local count = 0
  for key in pairs(tbl) do
    if type(key) ~= 'number' or key < 1 or key % 1 ~= 0 then
      return false
    end
    count = count + 1
  end
  return count == #tbl
end

local function merge(default, overrides)
  if type(default) ~= 'table' or type(overrides) ~= 'table' then
    return vim.deepcopy(overrides)
  end

  -- Replace arrays rather than merging by index, so users can replace sections cleanly.
  if is_list(default) or (is_list(overrides) and next(overrides) ~= nil) then
    return vim.deepcopy(overrides)
  end

  local result = vim.deepcopy(default)
  for key, value in pairs(overrides) do
    result[key] = merge(default[key], value)
  end
  return result
end

--- Get the default Lualine config merged with user overrides.
---@param opts table? Lualine options to override the defaults
---@return table config
function M.get_config(opts)
  return merge(defaults, opts or {})
end

--- Configure Lualine with tabnv's default UI and optional user overrides.
---@param opts table? Lualine options to override the defaults
---@return table config The effective Lualine configuration
function M.setup(opts)
  local ok, lualine = pcall(require, 'lualine')
  if not ok then
    error('tabnv.integrations.lualine requires nvim-lualine/lualine.nvim', 2)
  end

  local config = M.get_config(opts)
  lualine.setup(config)
  return config
end

return M
