local M = {}

function M.register_keymaps(grok_code, config)
  local km = config.keymaps or {}
  local toggle = km.toggle or {}

  -- Normal mode toggle
  if toggle.normal and toggle.normal ~= false then
    vim.keymap.set('n', toggle.normal, function() grok_code.toggle() end,
      { desc = 'Toggle Grok Build', noremap = true, silent = true })
  end

  -- Terminal mode toggle (while inside the grok TUI)
  if toggle.terminal and toggle.terminal ~= false then
    vim.keymap.set('t', toggle.terminal, function()
      vim.cmd('stopinsert')
      grok_code.toggle()
    end, { desc = 'Toggle Grok Build (from terminal)', noremap = true, silent = true })
  end

  -- Variants
  if toggle.variants then
    for vname, key in pairs(toggle.variants) do
      if key and key ~= false then
        vim.keymap.set('n', key, function()
          grok_code.toggle_with_variant(vname)
        end, { desc = 'Grok Build --' .. vname, noremap = true, silent = true })
      end
    end
  end

  -- Context reference actions (file / range / line / select)
  -- These are the "send to grok terminal" helpers.

  if km.send_file_ref and km.send_file_ref ~= false then
    vim.keymap.set('n', km.send_file_ref, function()
      grok_code.send_file_ref()
    end, { desc = 'Send @file reference to grok terminal', noremap = true, silent = true })
  end

  if km.send_range_ref and km.send_range_ref ~= false then
    -- Visual mode: capture live selection using 'v' mark + current line
    vim.keymap.set('x', km.send_range_ref, function()
      local start_line = vim.fn.line('v')
      local end_line = vim.fn.line('.')
      if start_line > end_line then
        start_line, end_line = end_line, start_line
      end
      grok_code.send_range_ref(start_line, end_line)
    end, { desc = 'Send @file:range (or single line) reference to grok terminal (visual)', noremap = true, silent = true })
  end

  if km.send_line_ref and km.send_line_ref ~= false then
    vim.keymap.set('n', km.send_line_ref, function()
      grok_code.send_line_ref()
    end, { desc = 'Send @file:line reference to grok terminal', noremap = true, silent = true })
  end

  if km.select and km.select ~= false then
    vim.keymap.set('n', km.select, function()
      grok_code.select()
    end, { desc = 'Grok select action (predefined prompts)', noremap = true, silent = true })
  end
end

function M.setup_terminal_navigation(grok_code, config)
  -- Placeholder for future per-buffer nav if needed
end

return M
