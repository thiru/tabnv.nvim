--- Native desktop notifications for supported operating systems.
local M = {}

local function powershell_quote(value)
  return "'" .. value:gsub("'", "''") .. "'"
end

local function get_command(title, body)
  local system = vim.uv.os_uname().sysname

  if system == 'Linux' then
    if vim.fn.executable('notify-send') == 0 then
      return nil
    end
    return { 'notify-send', '--app-name=tabnv', title, body }
  elseif system == 'Darwin' then
    if vim.fn.executable('osascript') == 0 then
      return nil
    end
    local script = table.concat({
      'on run argv',
      ' display notification (item 2 of argv) with title (item 1 of argv)',
      'end run',
    }, '\n')
    return { 'osascript', '-e', script, title, body }
  elseif system == 'Windows_NT' then
    if vim.fn.executable('powershell.exe') == 0 then
      return nil
    end
    local script = table.concat({
      'Add-Type -AssemblyName System.Windows.Forms;',
      'Add-Type -AssemblyName System.Drawing;',
      '$n = New-Object System.Windows.Forms.NotifyIcon;',
      '$n.Icon = [System.Drawing.SystemIcons]::Information;',
      '$n.Visible = $true;',
      '$n.BalloonTipTitle = ' .. powershell_quote(title) .. ';',
      '$n.BalloonTipText = ' .. powershell_quote(body) .. ';',
      '$n.ShowBalloonTip(5000);',
      'Start-Sleep -Seconds 6;',
      '$n.Dispose();',
    }, ' ')
    return {
      'powershell.exe',
      '-NoProfile',
      '-NonInteractive',
      '-WindowStyle',
      'Hidden',
      '-Command',
      script,
    }
  end

  return nil
end

--- Send a desktop notification if a native notifier is available.
---@param title string
---@param body string
function M.send(title, body)
  if type(vim.system) ~= 'function' then
    return
  end

  local command = get_command(title, body)
  if not command then
    return
  end

  -- Notifications should never interrupt Neovim if a desktop service is missing
  -- or rejects the notification.
  pcall(vim.system, command, { text = true }, function() end)
end

return M
