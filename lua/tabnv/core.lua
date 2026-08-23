--- Contains the core functionality of this plugin.

local M = {
  state = {}
}

local u = require('tabnv.utils')
local ws = require('tabnv.workspace')

--- Setup core aspects of the plugin.
---@param config tabnv.Config
function M.setup(config)
  M.config = config
  M.save_original_opts()
  M.set_keybinds()
  M.create_usercmds()
  M.create_autocmds()
  ws.setup()
end

function M.save_original_opts()
  M.state.original_opts = {
    background = vim.opt.background:get(),
    cursorline = vim.opt.cursorline:get(),
    neovide_opacity = vim.g.neovide_opacity,
    number = vim.opt.number:get(),
    relativenumber = vim.opt.relativenumber:get(),
    scrolloff = vim.opt.scrolloff:get(),
    signcolumn = vim.opt.signcolumn:get(),
    title = vim.opt.title:get(),
  }
end

--- Set (subjectively) optimal settings for a good terminal experience.
function M.set_term_opts()
  vim.opt.background = 'dark'
  vim.opt.cursorline = false
  vim.opt.scrolloff = 0
  vim.opt.number = false
  vim.opt.relativenumber = false
  vim.opt.signcolumn = 'no'
  vim.opt.title = true

  if M.config.colorscheme and (vim.g.colors_name ~= M.config.colorscheme) then
    M.state.original_opts.colors_name = vim.g.colors_name
    vim.cmd.colorscheme(M.config.colorscheme)
  end

  M.state.is_term_tab = true
end

-- Undo options set in `M.set_term_opts`.
function M.unset_term_opts()
  vim.opt.background = M.state.original_opts.background
  vim.opt.cursorline = M.state.original_opts.cursorline
  vim.opt.scrolloff = M.state.original_opts.scrolloff
  vim.opt.number = M.state.original_opts.number
  vim.opt.relativenumber = M.state.original_opts.relativenumber
  vim.opt.signcolumn = M.state.original_opts.signcolumn
  vim.opt.title = M.state.original_opts.title

  if M.state.original_opts.colors_name then
    vim.cmd.colorscheme(M.state.original_opts.colors_name)
  end

  M.state.is_term_tab = false
end

--- Create user commands.
function M.create_usercmds()
  vim.api.nvim_create_user_command('TabnvStart', function()
    M.set_term_opts()
    vim.cmd.terminal()
    vim.cmd.startinsert()
  end, {})
end

--- Create various auto-commands to provide a more seamless experience such as:
function M.create_autocmds()
  -- NOTE: use these two autocmds to save and restore terminal tab mode & coord
  vim.api.nvim_create_autocmd('WinLeave', {
    callback = function()
      if u.is_terminal_buf() then
        u.save_tab_mode_and_coord()
      end
    end,
    group = vim.api.nvim_create_augroup('tabnv_winleave', {clear = true}),
    pattern = '*',
  })
  vim.api.nvim_create_autocmd('WinEnter', {
    callback = function()
      if u.is_terminal_buf() then
        u.restore_tab_mode_and_coord()
      end
    end,
    group = vim.api.nvim_create_augroup('tabnv_winenter', {clear = true}),
    pattern = '*',
  })

  vim.api.nvim_create_autocmd('BufEnter', {
    callback = function()
      u.update_window_title()
    end,
    group = vim.api.nvim_create_augroup('tabnv_bufenter', {clear = true}),
    pattern = '*',
  })

  vim.api.nvim_create_autocmd('TabEnter', {
    callback = function ()
      u.update_window_title()

      vim.schedule(function ()
        if u.is_terminal_buf() then
          local ok, tabdir = pcall(vim.api.nvim_tabpage_get_var, 0, 'tabdir')
          if ok then
            vim.fn.chdir(tabdir)
          end

          if M.config.neovide_opacity
              and vim.g.neovide
              and vim.g.neovide_opacity ~= M.config.neovide_opacity then
            vim.g.neovide_opacity = M.config.neovide_opacity
          end

          if M.config.on_tab_changed then
            M.config.on_tab_changed(true)
          end
          if not M.state.is_term_tab then
            M.set_term_opts()
          end
        else
          if M.config.neovide_opacity
              and vim.g.neovide
              and vim.g.neovide_opacity ~= M.state.original_opts.neovide_opacity then
            vim.g.neovide_opacity = M.state.original_opts.neovide_opacity
          end

          if M.config.on_tab_changed then
            M.config.on_tab_changed(false)
          end
          if M.state.is_term_tab then
            M.unset_term_opts()
          end
        end
      end)
    end,
    group = vim.api.nvim_create_augroup('tabnv_tabenter', {clear = true}),
    pattern = '*',
  })

  -- Avoid 'modifiable is off' message and allow terminal to be editable
  vim.api.nvim_create_autocmd('TermOpen', {
    callback = function()
      vim.opt_local.modifiable = true
    end,
    group = vim.api.nvim_create_augroup('tabnv_termopen', {clear = true}),
    pattern = '*',
  })

  vim.api.nvim_create_autocmd('TermClose', {
    callback = function()
      -- Avoid "Process exited 0" message
      vim.api.nvim_input('<CR>')
    end,
    group = vim.api.nvim_create_augroup('tabnv_termclose', {clear = true}),
    pattern = '*',
  })

  -- Close tab if empty, or exit Neovim altogether if this is also the last tab
  vim.api.nvim_create_autocmd('TermLeave', {
    callback = function()
      local leaving_tab = vim.api.nvim_get_current_tabpage()
      vim.schedule(function()
        -- NOTE: only auto-close if we're still on the tab that was left. The
        -- scheduled callback may otherwise run after the user has switched to
        -- another (empty) tab, and we'd close the wrong one.
        if vim.api.nvim_get_current_tabpage() ~= leaving_tab then
          return
        end
        if M.state.is_term_tab and u.is_empty_tab(leaving_tab) then
          local tabs = vim.api.nvim_list_tabpages()
          if #tabs == 1 then
            vim.cmd.quit()
          else
            vim.cmd.tabclose()
          end
        end
      end)
    end,
    group = vim.api.nvim_create_augroup('tabnv_termleave', {clear = true}),
    pattern = '*',
  })

  -- Use CWD for tab name if custom name not already set
  -- NOTE: The DirChangedPre event is used instead of DirChanged in order capture the original
  -- path before vim alters it by resolving symlinks.
  vim.api.nvim_create_autocmd('DirChangedPre', {
    callback = function(ev)
      u.auto_set_tab_name(ev.file)
      u.update_window_title()
    end,
    group = vim.api.nvim_create_augroup('tabnv_dirchangedpre', {clear = true}),
    pattern = '*',
  })

  -- Handles OSC 7 dir change requests (taken from vim help)
  vim.api.nvim_create_autocmd({'TermRequest'}, {
    callback = function(ev)
      local val, n = string.gsub(ev.data.sequence, '\027]7;file://[^/]*', '')
      if n > 0 then
        -- OSC 7: dir-change
        local dir = val
        if vim.fn.isdirectory(dir) == 0 then
          vim.notify('invalid dir: '..dir)
          return
        end
        vim.b[ev.buf].osc7_dir = dir
        if vim.api.nvim_get_current_buf() == ev.buf then
          vim.cmd.cd(dir)
          u.auto_set_tab_name(dir)
          u.update_window_title()
        end
      end
    end,
    group = vim.api.nvim_create_augroup('tabnv_termrequest', {clear = true})
  })
end

--- Create a new tab with a terminal and enter insert mode.
function M.new_tab()
  vim.cmd('tabnew')

  M.set_term_opts()

  if M.config.on_before_term_created then
    M.config.on_before_term_created()
  end

  vim.cmd.terminal()

  if M.config.on_after_term_created then
    M.config.on_after_term_created()
  end

  vim.cmd.startinsert()

  u.auto_set_tab_name(vim.fn.getcwd())
end

--- Create a centred, floating window with a terminal and enter insert mode.
function M.new_float_term()
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

  vim.cmd.terminal()
  vim.cmd.startinsert()
end

--- Show prompt to rename the current tab.
function M.rename_tab_prompt()
  local curr_name = u.get_tab_name()
  local new_name = vim.fn.input('Tab Name: ', curr_name)

  if #new_name > 0 then
    u.set_tab_name(new_name)
    u.update_window_title()
  end
end

--- Show prompt to set a window prefix.
function M.set_window_prefix_prompt()
  local curr_prefix = vim.g.tabnv_window_prefix or ''
  local new_prefix = vim.fn.input('Window Prefix: ', curr_prefix)

  if #new_prefix > 0 then
    vim.g.tabnv_window_prefix = new_prefix
    u.update_window_title()
  end
end

--- Define key bindings. These are mostly leader-key-based.
function M.set_keybinds()
  -- New buffer tab
  vim.keymap.set({'n', 't'}, '<C-t>', '<CMD>tabnew<CR>', {desc = 'New editor (tab)'})

  -- New terminal tab
  vim.keymap.set({'n', 't'}, '<C-;>', M.new_tab, {desc = 'New terminal (tab)'})

  -- New floating, centred terminal
  vim.keymap.set('n', M.config.leader .. 'f', M.new_float_term, {desc = 'New terminal (float)'})

  -- Terminal ESC
  vim.keymap.set('t', '<C-space>', '<C-\\><C-n>', {desc = 'Terminal mode -> normal mode'})

  -- Up/down
  vim.keymap.set({'c', 't'}, '<C-j>', '<Down>', {desc = 'Down arrow'})
  vim.keymap.set({'c', 't'}, '<C-k>', '<Up>', {desc = 'Up arrow'})

  -- Paste
  vim.keymap.set('t', '<C-v>',
    function()
      local terminal_job_id = vim.fn.getbufvar(vim.fn.bufnr(), 'terminal_job_id')
      vim.api.nvim_chan_send(terminal_job_id, vim.fn.getreg('+'))
    end,
    {desc = 'Paste from system clipboard'})
  vim.keymap.set('t', '<C-S-v>', '<C-\\><C-n>pi', { desc = 'Paste from default register' })

  -- Tab close
  vim.keymap.set('n', M.config.leader .. 'd', '<CMD>tabclose<CR>', {desc = 'Close tab'})

  -- New vertical split terminal
  vim.keymap.set(
    'n',
    M.config.leader .. 'v',
    function()
      vim.cmd.vsplit()
      vim.cmd.enew()
      vim.cmd.terminal()
      vim.cmd.startinsert()
    end,
    {desc = 'New terminal (vertical split)'})

  -- New horizontal split terminal
  vim.keymap.set(
    'n',
    M.config.leader .. 'h',
    function()
      vim.cmd.split()
      vim.cmd.enew()
      vim.cmd.terminal()
      vim.cmd.startinsert()
    end,
    {desc = 'New terminal (horizontal split)'})

  -- Rename tab
  vim.keymap.set('n', M.config.leader .. 'r', M.rename_tab_prompt, {desc = 'Rename tab'})

  -- SSH picker
  vim.keymap.set('n', M.config.leader .. 's', '<CMD>SshPicker<CR>', {desc = 'Launch [S]SH connection picker'})

  -- Window prefix
  vim.keymap.set('n', M.config.leader .. 'p', M.set_window_prefix_prompt, {desc = 'Set Window [P]refix'})

  -- Quit
  vim.keymap.set(
    { 'n', 'v' }, '<leader>q',
    function()
      if #vim.api.nvim_list_tabpages() <= 1 then
        vim.cmd.quitall()
      else
        vim.cmd.tabclose()
      end
    end,
    { desc = 'Exit/Close Tab' })
  vim.keymap.set({ 'n', 'v' }, '<leader>Q', '<CMD>qall!<CR>', { desc = 'Exit (ignore unsaved changes/tabs)' })
end

return M
