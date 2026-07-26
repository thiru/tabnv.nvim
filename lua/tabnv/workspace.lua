local M = {
  state = {
    all_workspaces = {},
    active_workspace = nil,
    previous_workspace = nil,
  }
}

local u = require('tabnv.utils')

function M.setup()
  M.state.all_workspaces[1] = {id = 1, tabs = {}}
  M.state.active_workspace = M.state.all_workspaces[1]
  M.add_tab_to_workspace()

  -- Go to tab: prev/next
  vim.keymap.set({'n', 't'}, '<C-h>', M.go_to_prev_tab, {desc='Go to previous tab'})
  vim.keymap.set({'n', 't'}, '<C-l>', M.go_to_next_tab, {desc='Go to next tab'})

  -- Go to workspace: prev/next
  vim.keymap.set({'n', 't'}, '<C-,>', M.go_to_prev_workspace, {desc='Go to previous workspace'})
  vim.keymap.set({'n', 't'}, '<C-.>', M.go_to_next_workspace, {desc='Go to next workspace'})

  -- Go to workspace: last active
  vim.keymap.set({'n', 't'}, '<C-`>', M.go_to_last_active_workspace, {desc='Go to last active workspace'})

  -- Go to workspace: 1 -> 10
  vim.keymap.set({'n', 't'}, '<C-1>', function() M.go_to_workspace_by_index(1) end, {desc='Go to workspace 1'})
  vim.keymap.set({'n', 't'}, '<C-2>', function() M.go_to_workspace_by_index(2) end, {desc='Go to workspace 2'})
  vim.keymap.set({'n', 't'}, '<C-3>', function() M.go_to_workspace_by_index(3) end, {desc='Go to workspace 3'})
  vim.keymap.set({'n', 't'}, '<C-4>', function() M.go_to_workspace_by_index(4) end, {desc='Go to workspace 4'})
  vim.keymap.set({'n', 't'}, '<C-5>', function() M.go_to_workspace_by_index(5) end, {desc='Go to workspace 5'})
  vim.keymap.set({'n', 't'}, '<C-6>', function() M.go_to_workspace_by_index(6) end, {desc='Go to workspace 6'})
  vim.keymap.set({'n', 't'}, '<C-7>', function() M.go_to_workspace_by_index(7) end, {desc='Go to workspace 7'})
  vim.keymap.set({'n', 't'}, '<C-8>', function() M.go_to_workspace_by_index(8) end, {desc='Go to workspace 8'})
  vim.keymap.set({'n', 't'}, '<C-9>', function() M.go_to_workspace_by_index(9) end, {desc='Go to workspace 9'})
  vim.keymap.set({'n', 't'}, '<C-0>', function() M.go_to_workspace_by_index(10) end, {desc='Go to workspace 10'})

  -- Move tab: left/right
  vim.keymap.set({'n', 't'}, '<C-S-h>', M.move_tab_left, {desc='Move tab left'})
  vim.keymap.set({'n', 't'}, '<C-S-l>', M.move_tab_right, {desc='Move tab right'})

  -- Move tab: to workspace 1 -> 10
  vim.keymap.set({'n', 't'}, '<C-!>', function() M.move_tab_to_workspace(1) end, {desc='Move tab to workspace 1'})
  vim.keymap.set({'n', 't'}, '<C-@>', function() M.move_tab_to_workspace(2) end, {desc='Move tab to workspace 2'})
  vim.keymap.set({'n', 't'}, '<C-#>', function() M.move_tab_to_workspace(3) end, {desc='Move tab to workspace 3'})
  vim.keymap.set({'n', 't'}, '<C-$>', function() M.move_tab_to_workspace(4) end, {desc='Move tab to workspace 4'})
  vim.keymap.set({'n', 't'}, '<C-%>', function() M.move_tab_to_workspace(5) end, {desc='Move tab to workspace 5'})
  vim.keymap.set({'n', 't'}, '<C-^>', function() M.move_tab_to_workspace(6) end, {desc='Move tab to workspace 6'})
  vim.keymap.set({'n', 't'}, '<C-&>', function() M.move_tab_to_workspace(7) end, {desc='Move tab to workspace 7'})
  vim.keymap.set({'n', 't'}, '<C-*>', function() M.move_tab_to_workspace(8) end, {desc='Move tab to workspace 8'})
  vim.keymap.set({'n', 't'}, '<C-(>', function() M.move_tab_to_workspace(9) end, {desc='Move tab to workspace 9'})
  vim.keymap.set({'n', 't'}, '<C-)>', function() M.move_tab_to_workspace(10) end, {desc='Move tab to workspace 10'})

  vim.api.nvim_create_autocmd('TabNew', {
    callback = function()
      M.add_tab_to_workspace()
    end,
    group = vim.api.nvim_create_augroup('tabnv_workspace_tabnew', {clear = true}),
    pattern = '*',
  })

  vim.api.nvim_create_autocmd('TabEnter', {
    callback = function()
      if M.state.active_workspace then
        M.state.active_workspace.last_active_tab = vim.api.nvim_get_current_tabpage()
      end
    end,
    group = vim.api.nvim_create_augroup('tabnv_workspace_tabenter', {clear = true}),
    pattern = '*',
  })

  vim.api.nvim_create_autocmd('TabClosedPre', {
    callback = function()
      M.remove_tab_from_workspace()
    end,
    group = vim.api.nvim_create_augroup('tabnv_workspace_tabclosedpre', {clear = true}),
    pattern = '*',
  })
end

function M.statusline_text()
  local active_workspace_id = M.state.active_workspace.id
  local workspaces = M.state.all_workspaces
  local workspace_ids = vim.tbl_keys(workspaces)
  table.sort(workspace_ids)

  return table.concat(
    vim.tbl_map(
      function(id)
        if id == active_workspace_id then
          return string.format('%s%d%s',
          u.to_superscript(M.get_active_tab_idx()),
          id,
          u.to_superscript(#M.state.active_workspace.tabs))
        else
          return tostring(id)
        end
      end,
      workspace_ids),
      ' ')
end

function M.get_active_tab_idx()
  local tabs = M.state.active_workspace.tabs
  local active_tab_idx = 1
  local curr_tab = vim.api.nvim_get_current_tabpage()

  if #tabs > 1 then
    for i = 2, #tabs do
      if tabs[i] == curr_tab then
        active_tab_idx = i
        break
      end
    end
  end

  return active_tab_idx
end

function M.add_tab_to_workspace()
  local new_tab = vim.api.nvim_get_current_tabpage()
  local tabs = M.state.active_workspace.tabs
  local insert_pos = #tabs + 1

  local last_active_tab = M.state.active_workspace.last_active_tab
  if last_active_tab then
    for i = 1, #tabs do
      if tabs[i] == last_active_tab then
        insert_pos = i + 1
        break
      end
    end
  end

  table.insert(tabs, insert_pos, new_tab)
end

function M.remove_tab_from_workspace()
  local curr_tab = vim.api.nvim_get_current_tabpage()
  local tabs = M.state.active_workspace.tabs
  local workspaces = M.state.all_workspaces

  -- when there's only 1 tab we need to delete this workspace and select the previous one
  if #tabs == 1 then
    local curr_workspace_id = M.state.active_workspace.id
    local workspace_ids = vim.tbl_keys(workspaces)
    table.sort(workspace_ids)

    if #workspace_ids == 1 then
      return
    end

    table.remove(tabs, 1)

    vim.schedule(function()
      workspaces[curr_workspace_id] = nil

      local prev_idx = #workspace_ids
      for j = #workspace_ids, 1, -1 do
        if workspace_ids[j] < curr_workspace_id then
          prev_idx = j
          break
        end
      end

      local new_key = workspace_ids[prev_idx]
      M.state.previous_workspace = M.state.active_workspace
      M.state.active_workspace = workspaces[new_key]
      vim.api.nvim_set_current_tabpage(M.get_workspace_target_tab(workspaces[new_key]))
    end)
  else
    for i = 1, #tabs do
      if tabs[i] == curr_tab then
        table.remove(tabs, i)
        break
      end
    end
  end
end

function M.go_to_prev_tab()
  local curr_tab = vim.api.nvim_get_current_tabpage()
  local tabs = M.state.active_workspace.tabs

  if #tabs == 1 then
    return
  elseif tabs[1] == curr_tab then
    vim.api.nvim_set_current_tabpage(tabs[#tabs])
    return
  end

  for i = 2, #tabs do
    if tabs[i] == curr_tab then
      local prev_tab = tabs[i - 1]
      vim.api.nvim_set_current_tabpage(prev_tab)
      break
    end
  end
end

function M.go_to_next_tab()
  local curr_tab = vim.api.nvim_get_current_tabpage()
  local tabs = M.state.active_workspace.tabs

  if #tabs == 1 then
    return
  elseif tabs[#tabs] == curr_tab then
    vim.api.nvim_set_current_tabpage(tabs[1])
    return
  end

  for i = 1, #tabs do
    if tabs[i] == curr_tab then
      local next_tab = tabs[i + 1]
      vim.api.nvim_set_current_tabpage(next_tab)
      break
    end
  end
end

function M.get_workspace_target_tab(workspace)
  if workspace.last_active_tab then
    for _, tab in ipairs(workspace.tabs) do
      if tab == workspace.last_active_tab then
        return tab
      end
    end
  end
  return workspace.tabs[1]
end

function M.go_to_workspace_by_index(idx)
  local workspaces = M.state.all_workspaces
  if idx < 1 or idx == M.state.active_workspace.id then
    return
  end

  if workspaces[idx] then
    M.state.previous_workspace = M.state.active_workspace
    M.state.active_workspace = workspaces[idx]
    vim.api.nvim_set_current_tabpage(M.get_workspace_target_tab(workspaces[idx]))
  else
    local new_workspace = {id = idx, tabs = {}}
    M.state.active_workspace = new_workspace
    workspaces[idx] = new_workspace
    vim.cmd('tabnew')
  end
end

function M.go_to_prev_workspace()
  local workspaces = M.state.all_workspaces
  local workspace_ids = vim.tbl_keys(workspaces)
  table.sort(workspace_ids)

  if #workspace_ids <= 1 then
    return
  end

  local curr_workspace_id = M.state.active_workspace.id

  for i = #workspace_ids, 1, -1 do
    if workspace_ids[i] < curr_workspace_id then
      M.state.previous_workspace = M.state.active_workspace
      M.state.active_workspace = workspaces[workspace_ids[i]]
      vim.api.nvim_set_current_tabpage(M.get_workspace_target_tab(workspaces[workspace_ids[i]]))
      return
    end
  end

  M.state.previous_workspace = M.state.active_workspace
  M.state.active_workspace = workspaces[workspace_ids[#workspace_ids]]
  vim.api.nvim_set_current_tabpage(M.get_workspace_target_tab(workspaces[workspace_ids[#workspace_ids]]))
end

function M.go_to_next_workspace()
  local workspaces = M.state.all_workspaces
  local workspace_ids = vim.tbl_keys(workspaces)
  table.sort(workspace_ids)

  if #workspace_ids <= 1 then
    return
  end

  local curr_workspace_id = M.state.active_workspace.id

  for i = 1, #workspace_ids do
    if workspace_ids[i] > curr_workspace_id then
      M.state.previous_workspace = M.state.active_workspace
      M.state.active_workspace = workspaces[workspace_ids[i]]
      vim.api.nvim_set_current_tabpage(M.get_workspace_target_tab(workspaces[workspace_ids[i]]))
      return
    end
  end

  M.state.previous_workspace = M.state.active_workspace
  M.state.active_workspace = workspaces[workspace_ids[1]]
  vim.api.nvim_set_current_tabpage(M.get_workspace_target_tab(workspaces[workspace_ids[1]]))
end

function M.go_to_last_active_workspace()
  local prev = M.state.previous_workspace
  local curr = M.state.active_workspace
  if not prev then
    return
  end
  M.state.previous_workspace = curr
  M.state.active_workspace = prev
  vim.api.nvim_set_current_tabpage(M.get_workspace_target_tab(prev))
end

function M.move_tab_to_workspace(target_ws_idx)
  -- don't do anything if current/same workspace is selected
  if target_ws_idx == M.state.active_workspace.id then
    return
  end

  local workspace_to_save = M.state.active_workspace

  local curr_tab = vim.api.nvim_get_current_tabpage()
  local curr_tabs = workspace_to_save.tabs

  -- remove tab from the current workspace
  for i = 1, #curr_tabs do
    if curr_tabs[i] == curr_tab then
      table.remove(curr_tabs, i)
      break
    end
  end

  local workspaces = M.state.all_workspaces
  local curr_id = workspace_to_save.id

  -- if current workspace is now empty, remove the entire workspace
  if #curr_tabs == 0 then
    workspaces[curr_id] = nil
  end

  -- create target workspace if it doesn't exist
  if not workspaces[target_ws_idx] then
    workspaces[target_ws_idx] = {id = target_ws_idx, tabs = {}}
  end

  -- add tab after the last active tab in the target workspace
  local target_ws = workspaces[target_ws_idx]
  local insert_pos = #target_ws.tabs + 1
  local last_active_tab = target_ws.last_active_tab
  if last_active_tab then
    for i = 1, #target_ws.tabs do
      if target_ws.tabs[i] == last_active_tab then
        insert_pos = i + 1
        break
      end
    end
  end
  table.insert(target_ws.tabs, insert_pos, curr_tab)

  M.state.previous_workspace = workspace_to_save
  M.state.active_workspace = target_ws

  vim.api.nvim_cmd({cmd='redrawstatus'}, {})
end

function M.move_tab_left()
  local curr_tab = vim.api.nvim_get_current_tabpage()
  local tabs = M.state.active_workspace.tabs

  if #tabs <= 1 then
    return
  end

  for i = 1, #tabs do
    if tabs[i] == curr_tab then
      if i == 1 then
        return
      end
      tabs[i], tabs[i - 1] = tabs[i - 1], tabs[i]
      break
    end
  end
  vim.api.nvim_cmd({cmd='redrawstatus'}, {})
end

function M.move_tab_right()
  local curr_tab = vim.api.nvim_get_current_tabpage()
  local tabs = M.state.active_workspace.tabs

  if #tabs <= 1 then
    return
  end

  for i = 1, #tabs do
    if tabs[i] == curr_tab then
      if i == #tabs then
        return
      end
      tabs[i], tabs[i + 1] = tabs[i + 1], tabs[i]
      break
    end
  end
  vim.api.nvim_cmd({cmd='redrawstatus'}, {})
end

return M
