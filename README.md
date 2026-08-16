# tabnv

<div align="center">
  <img src="logo.svg" alt="logo">
</div>

## what

a [neovim](https://neovim.io/) plugin that turns your editor into a powerful terminal multiplexer

## why

- I wanted a terminal emulator that had the following features
- even popular, modern terminals like Alacritty, Ghostty, Kitty and Wezterm are missing (some or all of) these

### goals

- can leverage the full power of vim to navigate terminal output
- support for buffers, windows, tabs and workspaces
- works natively on all platforms (linux, mac, windows)
  - I use [neovide](https://neovide.dev/) for this

### non-goals

- session persistence
  - e.g. as in gnu screen or tmux
- blazing speed
  - neovim's terminal emulator will not compete with displaying output as fast as modern gpu-accelerated terminals

## how

### installation

#### vim.pack

```lua
vim.pack.add({'https://github.com/thiru/tabnv.nvim'})
require('tabnv').setup()
```

#### lazy.nvim

```lua
{
  'thiru/tabnv.nvim',
  ---@type tabnv.Config
  opts = {},
}
```

optional dependency if using the SSH picker (pick one):
- [telescope](https://github.com/nvim-telescope/telescope.nvim)
- [fzf-lua](https://github.com/ibhagwan/fzf-lua)

### usage

- note that the default `leader` key is ` t`
- start neovim normally
  - `<C-;>` to get a tab with a terminal
  - `<C-t>` to get a tab with a regular empty buffer
- start neovim with a terminal
  - `nvim +TabnvStart`

#### generic key binds (terminal mode)

| Keymap      | Description                 |
|-------------|-----------------------------|
| `<C-space>` | Escape terminal mode        |
| `<C-v>`     | Paste from system clipboard |
| `<C-j>`     | Down arrow                  |
| `<C-k>`     | Up arrow                    |

#### tab-related key binds

| Keymap      | Description                                      |
|-------------|--------------------------------------------------|
| `<C-t>`     | New tab (regular buffer)                         |
| `<C-;>`     | New terminal tab                                 |
| `<leader>v` | New terminal (vertical split)                    |
| `<leader>h` | New terminal (horizontal split)                  |
| `<leader>f` | New floating, centred terminal                   |
| `<leader>r` | Rename current tab                               |
| `<leader>p` | Set a window prefix (shown in the title)         |
| `<leader>s` | Launch SSH connection picker                     |
| `<leader>d` | Close current tab                                |
| `<leader>q` | Close current tab (or quit if it's the last tab) |
| `<leader>Q` | Exit (ignore unsaved changes/tabs)               |

#### workspace key binds

| Keymap          | Description                           |
|-----------------|---------------------------------------|
| `<C-h>`         | Go to previous tab (within workspace) |
| `<C-l>`         | Go to next tab (within workspace)     |
| `<C-.>`         | Go to next workspace                  |
| `<C-,>`         | Go to previous workspace              |
| ``<C-`>``       | Go to last active workspace           |
| `<C-1>`…`<C-0>` | Go to workspace 1–10                  |
| `<C-S-h>`       | Move current tab left                 |
| `<C-S-l>`       | Move current tab right                |
| `<C-!>`…`<C-)>` | Move current tab to workspace 1–10    |

**auto-start command**

you can specify a command to run when the terminal starts via a global variable:

```shell
nvim +TabnvStart --cmd 'lua vim.g.tabnv_auto_start_cmd = "htop"'
```

### config

- see [config.lua](./lua/tabnv/config.lua) for the full configuration with defaults
- below is a summary of the available options

```lua
{
  -- optional colour scheme override (useful if you prefer a different theme for terminals)
  colorscheme = nil,

  -- optional opacity to use for terminal tabs if running within Neovide
  neovide_opacity = nil,

  -- the "leader" key used for many key binds (see keymap tables below)
  -- this avoids conflicts with nested vim instances (similar to tmux's Ctrl-B)
  leader = ' t',

  -- callback invoked right before a terminal buffer is created
  on_before_term_created = nil,

  -- callback invoked right after a terminal buffer is created
  on_after_term_created = nil,

  -- callback invoked on tab change
  on_tab_changed = nil,

  ssh = {
    -- automatically reconnect SSH sessions when they disconnect
    auto_reconnect = true,

    -- automatically rename the tab to the SSH hostname when connecting
    auto_rename_tab = true,

    password_detection = {
      -- attempt to detect SSH password prompts and cache entered passwords
      enabled = true,

      -- lua patterns used to detect an SSH authentication request
      patterns = {
        'password:$',
        '^Enter passphrase for key.*:$',
      },
    },

    -- picker backend: 'auto' (try telescope first, then fzf-lua), 'telescope', or 'fzf-lua'
    picker = 'auto',
  },
}
```

### features

#### workspaces

- workspaces are a way to group related tabs together, similar to *sessions* in tmux or kitty
- each workspace has its own set of tabs, and tab navigation (`<C-h>` / `<C-l>`) is scoped to the active workspace
- a workspace is created automatically when you navigate to an unused workspace index (via `<C-1>`…`<C-0>`)
- empty workspaces are cleaned up automatically

##### statusline integration

the module exposes a function for use in your statusline:

- `require('tabnv.workspace').statusline_text()`
  – returns a string like `1 ²2⁴`
  - this indicates that there are two workspaces
  - where the second workspace is the active one and has the second of 4 tabs selected

#### automatic tab naming

- tabs are automatically named after their current working directory
- if a terminal's directory changes (via `cd` or OSC 7 escape sequences), the tab name updates accordingly
- if you manually rename a tab (e.g. via  `<leader>r`), the automatic naming is disabled for that tab
and your custom name is preserved.

#### window title

- the window/tab title is composed from
  - an optional window prefix (set via `<leader>p`)
  - the tab name itself

#### floating terminal

- a centred, floating terminal window can be opened with `<leader>f`
- this is useful for quick commands without leaving your current layout

#### osc 7 directory change support

- handles OSC 7 escape sequences (emitted by modern shells via [`osc7`](https://github.com/ohmyzsh/ohmyzsh/tree/master/plugins/osc7) or similar) to track directory changes inside the terminal
- the tab name and CWD are updated automatically

#### auto-close empty tabs

- when you exit a shell in a terminal tab (TermLeave), the tab is automatically closed if it's empty
- if it's the last tab, neovim quits entirely

#### tab mode and cursor position preservation

- saves and restores the mode (terminal Insert or Normal)
- and cursor position when switching between windows in a tab, so you don't lose your place

#### ssh connection picker

- the ssh picker parses `~/.ssh/config` and `~/.ssh/known_hosts` and lets you quickly connect to any host
- it supports **telescope.nvim** and **fzf-lua**
- start the picker with `<leader>s` or by running
  - `:SshPicker`
- the default action (`<CR>`) will replace the current buffer
- alternative actions let you open the connection in a
  - **new tab** (`<C-t>`)
  - **horizontal split** (`<C-s>`)
  - **vertical split** (`<C-v>`)

##### auto-reconnect

- when `ssh.auto_reconnect` is enabled (default: `true`)
  - the SSH session is wrapped in a loop
  - and prompts you to press ENTER to reconnect after the session ends

##### password detection & caching

- when `ssh.password_detection.enabled` is `true` (default)
  - terminal output is monitored for ssh password prompts
  - and caches entered password so you don't have to re-enter it
