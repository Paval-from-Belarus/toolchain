local M = {}

function M.register_commands(grok_code)
  local function cmd(name, fn, opts)
    vim.api.nvim_create_user_command(name, fn, opts or {})
  end

  cmd('GrokCode', function() grok_code.toggle() end, { desc = 'Toggle Grok Build terminal' })

  -- Variants from config
  if grok_code.config and grok_code.config.command_variants then
    for vname, _ in pairs(grok_code.config.command_variants) do
      local cname = 'GrokCode' .. vname:gsub('^%l', string.upper)
      cmd(cname, function() grok_code.toggle_with_variant(vname) end, { desc = 'Toggle Grok Build with --' .. vname })
    end
  end

  -- Convenience aliases matching common Claude patterns
  cmd('GrokCodeContinue', function() grok_code.toggle_with_variant('continue') end, { desc = 'Continue previous Grok session' })
  cmd('GrokCodeResume', function() grok_code.toggle_with_variant('resume') end, { desc = 'Resume Grok session picker' })

  cmd('GrokCodeInstallHelp', function()
    local term = require('grok-code.terminal')
    -- reuse the prompt logic by forcing a fake toggle that will hit the guard
    -- simpler: just show it directly
    local cfg = grok_code.config or require('grok-code.config').default_config
    local lines = {
      'Grok Build CLI (grok) install instructions:',
      '',
      '  ' .. (cfg.install and cfg.install.command or 'curl -fsSL https://x.ai/cli/install.sh | bash'),
      '',
      'Docs: ' .. (cfg.install and cfg.install.url or 'https://x.ai/cli'),
    }
    vim.notify(table.concat(lines, '\n'), vim.log.levels.INFO)
  end, { desc = 'Show Grok Build install instructions' })

  -- Raw / plain launcher — exactly the same as manually running the CLI in a terminal.
  -- Useful if you prefer to manage terminals yourself (like you do for Claude Code).
  cmd('Grok', function(opts)
    local cfg = grok_code.config or require('grok-code.config').default_config
    local cmd_base = cfg._resolved_command or cfg.command or 'grok'

    -- Check for the binary (with friendly install prompt)
    if vim.fn.executable(cmd_base) == 0 then
      -- Try common locations (keep in sync with terminal.lua)
      local candidates = {
        vim.fn.expand('~/.grok/bin/grok'),
        vim.fn.expand('~/.local/bin/grok'),
        '/usr/local/bin/grok',
      }
      local found = false
      for _, p in ipairs(candidates) do
        if vim.fn.executable(p) == 1 or (vim.fn.filereadable(p) == 1 and vim.fn.getfperm(p):match('x')) then
          cmd_base = p
          cfg._resolved_command = p
          found = true
          break
        end
      end
      if not found then
        local term = require('grok-code.terminal')
        if term.show_install_prompt then
          term.show_install_prompt(cfg)
        else
          vim.notify('grok not found.\nInstall: curl -fsSL https://x.ai/cli/install.sh | bash\nDocs: https://x.ai/cli', vim.log.levels.WARN)
        end
        return
      end
    end

    local args = opts.args or ''
    local full = cmd_base
    if args ~= '' then full = full .. ' ' .. args end

    -- Try to start in git root for consistency with agent workflows (same as managed toggle)
    local git_root = vim.fn.systemlist('git rev-parse --show-toplevel 2>/dev/null')[1]
    local launch_cmd = full
    if git_root and git_root ~= '' and vim.fn.isdirectory(git_root) == 1 then
      launch_cmd = 'cd ' .. vim.fn.shellescape(git_root) .. ' && ' .. full
    end

    -- Open as vertical split on the right side (side-panel style for agent)
    -- This is pure "open terminal view + run the real grok CLI"
    vim.cmd('botright vsplit')
    local ratio = (cfg.window and cfg.window.split_ratio) or 0.35
    local width = math.floor(vim.o.columns * ratio)
    vim.cmd('vertical resize ' .. width)
    vim.cmd('terminal ' .. launch_cmd)
    vim.cmd('setlocal bufhidden=hide')
    vim.cmd('file grok-' .. vim.fn.fnamemodify(vim.fn.getcwd(), ':t'))
    vim.cmd('startinsert')
  end, { nargs = '*', desc = 'Open plain terminal running grok (raw CLI reuse)' })

  -- New actions for sending context references to the grok terminal (raw CLI reuse)
  cmd('GrokSendFileRef', function() grok_code.send_file_ref() end, { desc = 'Append @current-file reference to grok terminal' })
  cmd('GrokSendRangeRef', function() grok_code.send_range_ref() end, { desc = 'Append @file:line or @file:line-line reference to grok terminal' })
  cmd('GrokSendLineRef', function() grok_code.send_line_ref() end, { desc = 'Append @file:line reference to grok terminal' })
  cmd('GrokSelect', function() grok_code.select() end, { desc = 'Pick a ready-to-use action/prompt and send it to grok terminal (with file context)' })
  cmd('GrokSendPrompt', function(opts)
    grok_code.send_prompt(opts.args)
  end, { nargs = '*', desc = 'Send a custom prompt to the grok terminal (auto adds file ref if missing)' })
end

return M
