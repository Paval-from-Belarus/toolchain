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

  if km.window_navigation then
    -- Only set when inside a grok terminal buffer? For simplicity we set global like the original often does.
    -- Users can disable if conflicting.
    vim.keymap.set('t', '<C-h>', [[<C-\><C-n><C-w>h]], { noremap = true, silent = true, desc = 'Window left' })
    vim.keymap.set('t', '<C-j>', [[<C-\><C-n><C-w>j]], { noremap = true, silent = true, desc = 'Window down' })
    vim.keymap.set('t', '<C-k>', [[<C-\><C-n><C-w>k]], { noremap = true, silent = true, desc = 'Window up' })
    vim.keymap.set('t', '<C-l>', [[<C-\><C-n><C-w>l]], { noremap = true, silent = true, desc = 'Window right' })
  end

  if km.scrolling then
    vim.keymap.set('t', '<C-f>', [[<C-\><C-n><C-f>i]], { noremap = true, silent = true, desc = 'Page down (re-enter insert with i)' })
    vim.keymap.set('t', '<C-b>', [[<C-\><C-n><C-b>i]], { noremap = true, silent = true, desc = 'Page up (re-enter insert with i)' })
  end
end

function M.setup_terminal_navigation(grok_code, config)
  -- Placeholder for future per-buffer nav if needed
end

return M
