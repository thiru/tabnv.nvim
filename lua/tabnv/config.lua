--- Plugin configuration with defaults.

local M = {}

---@class tabnv.Config
---@field leader string? A leader key is used for many key binds to avoid conflicting with nested vim instances. Tmux uses a similar approach with its default being CTRL-B.
---@field neovide_term_opacity number? Optional opacity to use for terminal tabs if running within Neovide.
---@field neovide_non_term_opacity number? Optional opacity to use for non-terminal tabs if running within Neovide.
---@field on_before_term_created function? If specified, this function will be called right before a terminal is created in a new tab.
---@field on_after_term_created function? If specified, this function will be called right after a terminal is created in a new tab.
---@field on_tab_changed function? If specified, this function will be called when the tab changes. It takes one parameter which indicates whether the current tab is a terminal mode tab.
---@field tab_name_as_command_max_length number? Maximum length of a running command used as a tab name.
---@field show_tab_index_superscript boolean? Show each tab's index as a superscript in the tabline.
---@field ssh.auto_reconnect boolean? Automatically prompt to reconnect disconnected sessions
---@field ssh.auto_rename_tab boolean? Automatically rename the current tab to the SSH connection name
---@field ssh.password_detection table? Attempt to detect SSH authentication requests. Passwords will be cached and reused for future connections.
---@field ssh.password_detection.enabled boolean? Enable SSH authentication request detection.
---@field ssh.password_detection.patterns string[]? Lua patterns used to detect an SSH authentication request
---@field ssh.picker string? Select the picker backend: 'auto' (try telescope first, fallback to fzf-lua), 'telescope', or 'fzf-lua'
M.config = {
  leader = '<C-;>',
  neovide_term_opacity = nil,
  neovide_non_term_opacity = nil,
  on_before_term_created = nil,
  on_after_term_created = nil,
  on_tab_changed = nil,
  tab_name_as_command_max_length = 30,
  show_tab_index_superscript = false,
  ssh = {
    auto_reconnect = true,
    auto_rename_tab = true,
    password_detection = {
      enabled = true,
      patterns = {
        'password:$',
        '^Enter passphrase for key.*:$'
      },
    },
    picker = 'auto'
  }
}

return M.config
