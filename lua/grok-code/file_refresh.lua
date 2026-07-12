local M = {}

local refresh_timer = nil

function M.setup(grok_code, config)
  if not config.refresh.enable then return end

  local augroup = vim.api.nvim_create_augroup('GrokCodeFileRefresh', { clear = true })

  vim.api.nvim_create_autocmd({
    'CursorHold', 'CursorHoldI', 'FocusGained', 'BufEnter',
    'InsertLeave', 'TextChanged', 'TermLeave', 'TermEnter', 'BufWinEnter',
  }, {
    group = augroup,
    pattern = '*',
    callback = function()
      if vim.fn.filereadable(vim.fn.expand('%')) == 1 then
        vim.cmd('checktime')
      end
    end,
    desc = 'Check for external file changes (Grok edits)',
  })

  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end

  refresh_timer = vim.loop.new_timer()
  if refresh_timer then
    refresh_timer:start(0, config.refresh.timer_interval, vim.schedule_wrap(function()
      local inst = grok_code.grok_code.current_instance
      local bufnr = inst and grok_code.grok_code.instances and grok_code.grok_code.instances[inst]
      if bufnr and vim.api.nvim_buf_is_valid(bufnr) and #vim.fn.win_findbuf(bufnr) > 0 then
        vim.cmd('silent! checktime')
      end
    end))
  end

  if config.refresh.show_notifications then
    vim.api.nvim_create_autocmd('FileChangedShellPost', {
      group = augroup,
      pattern = '*',
      callback = function()
        vim.notify('File changed on disk (by Grok). Buffer reloaded.', vim.log.levels.INFO)
      end,
    })
  end

  grok_code.grok_code.saved_updatetime = vim.o.updatetime

  vim.api.nvim_create_autocmd('TermOpen', {
    group = augroup,
    pattern = '*',
    callback = function()
      local buf = vim.api.nvim_get_current_buf()
      local name = vim.api.nvim_buf_get_name(buf)
      if name:match('grok%-code') then
        grok_code.grok_code.saved_updatetime = vim.o.updatetime
        vim.o.updatetime = config.refresh.updatetime
      end
    end,
  })

  vim.api.nvim_create_autocmd('TermClose', {
    group = augroup,
    pattern = '*',
    callback = function(args)
      local name = vim.api.nvim_buf_get_name(args.buf)
      if name:match('grok%-code') then
        vim.o.updatetime = grok_code.grok_code.saved_updatetime or vim.o.updatetime
        for id, b in pairs(grok_code.grok_code.instances or {}) do
          if b == args.buf then
            grok_code.grok_code.instances[id] = nil
            break
          end
        end
        vim.schedule(function()
          for _, w in ipairs(vim.fn.win_findbuf(args.buf)) do
            pcall(vim.api.nvim_win_close, w, true)
          end
          pcall(vim.api.nvim_buf_delete, args.buf, { force = true })
        end)
      end
    end,
  })
end

function M.cleanup()
  if refresh_timer then
    refresh_timer:stop()
    refresh_timer:close()
    refresh_timer = nil
  end
end

return M
