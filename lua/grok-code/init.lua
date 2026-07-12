---@mod grok-code Grok Build Neovim Integration
---@brief [[
--- A plugin for seamless integration between Grok Build (`grok` CLI) and Neovim.
--- Interface, keymaps, and behavior intentionally mirror popular claude-code.nvim plugins
--- (e.g. greggh/claude-code.nvim) so the interaction model feels identical.
---
--- Features:
--- - Toggle a persistent terminal running `grok`
--- - --continue / --resume variants
--- - Git-root aware working directory
--- - Auto file reload when Grok edits files
--- - If `grok` is not installed, shows clear instructions with official install command + docs link
---
--- Usage:
---   require('grok-code').setup()
---
--- Commands:
---   :GrokCode
---   :GrokCodeContinue
---   :GrokCodeResume
---   :GrokCodeInstallHelp
---@brief ]]

local config_mod = require('grok-code.config')
local commands = require('grok-code.commands')
local keymaps = require('grok-code.keymaps')
local file_refresh = require('grok-code.file_refresh')
local terminal = require('grok-code.terminal')
local git = require('grok-code.git')

local M = {}

M.config = {}
M.grok_code = terminal.terminal   -- for compatibility with some patterns

function M.force_insert_mode()
  terminal.force_insert_mode(M, M.config)
end

function M.toggle(extra_args)
  terminal.toggle(M, M.config, git, extra_args)

  local cur = M.grok_code.current_instance
  local bufnr = cur and M.grok_code.instances and M.grok_code.instances[cur]
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    keymaps.setup_terminal_navigation(M, M.config)
  end
end

function M.toggle_with_variant(variant_name)
  if not variant_name or not M.config.command_variants or not M.config.command_variants[variant_name] then
    return M.toggle()
  end

  local extra = M.config.command_variants[variant_name]
  terminal.toggle(M, M.config, git, extra)

  local cur = M.grok_code.current_instance
  local bufnr = cur and M.grok_code.instances and M.grok_code.instances[cur]
  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    keymaps.setup_terminal_navigation(M, M.config)
  end
end

function M.setup(user_config)
  M.config = config_mod.parse_config(user_config, false)

  vim.o.autoread = true

  -- File watcher for external changes (Grok edits)
  file_refresh.setup(M, M.config)

  commands.register_commands(M)
  keymaps.register_keymaps(M, M.config)
end

-- For health checks or introspection
M._has_grok = function()
  return vim.fn.executable('grok') == 1
end

----------------------------------------------------------
-- Sending references / context to a running grok terminal
-- This supports the "just open a terminal and run grok" workflow.
-- We append text (e.g. @file references) into the terminal's input.
----------------------------------------------------------

local terminal_mod = require('grok-code.terminal')

--- Find a buffer that looks like a grok terminal.
--- Prefers instances tracked by the managed toggle, falls back to any terminal
--- whose buffer name contains "grok".
local function find_grok_buf()
  -- If current buffer is already a grok terminal, use it (great for raw usage)
  local cur = vim.api.nvim_get_current_buf()
  if vim.api.nvim_buf_get_option(cur, 'buftype') == 'terminal' then
    local name = vim.api.nvim_buf_get_name(cur):lower()
    if name:match('grok') then
      return cur
    end
  end

  -- Managed instances (populated by :GrokCode / toggle)
  if M.grok_code and M.grok_code.instances then
    local current = M.grok_code.current_instance
    local b = current and M.grok_code.instances[current]
    if b and vim.api.nvim_buf_is_valid(b) and vim.api.nvim_buf_get_option(b, 'buftype') == 'terminal' then
      return b
    end
    for _, bufnr in pairs(M.grok_code.instances) do
      if bufnr and vim.api.nvim_buf_is_valid(bufnr) and vim.api.nvim_buf_get_option(bufnr, 'buftype') == 'terminal' then
        return bufnr
      end
    end
  end

  -- Fallback: scan all windows for any terminal whose name mentions grok
  -- (supports manually opened terminals with `grok` or the raw `:Grok` launcher)
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local bufnr = vim.api.nvim_win_get_buf(win)
    if vim.api.nvim_buf_get_option(bufnr, 'buftype') == 'terminal' then
      local name = vim.api.nvim_buf_get_name(bufnr):lower()
      if name:match('grok') then
        return bufnr
      end
    end
  end
  return nil
end

local function get_relative_file()
  local abs = vim.api.nvim_buf_get_name(0)
  if abs == '' then return nil end
  local git_root = require('grok-code.git').get_git_root() or vim.fn.getcwd()
  local rel = abs
  if git_root and abs:sub(1, #git_root) == git_root then
    rel = abs:sub(#git_root + 2)
  else
    rel = vim.fn.fnamemodify(abs, ':.')
  end
  return rel
end

--- Send arbitrary text to the grok terminal input.
--- @param text string
--- @param opts? {submit?: boolean, focus?: boolean}
function M.send(text, opts)
  opts = opts or {}
  local bufnr = find_grok_buf()
  if not bufnr then
    vim.notify('No grok terminal found. Open with :Grok or cvg', vim.log.levels.WARN)
    return false
  end

  local job = vim.b[bufnr] and vim.b[bufnr].terminal_job_id
  if not job then
    vim.notify('Grok terminal buffer has no active job', vim.log.levels.ERROR)
    return false
  end

  vim.fn.chansend(job, text)

  if opts.submit then
    vim.fn.chansend(job, '\r')
  end

  if opts.focus ~= false then
    local wins = vim.fn.win_findbuf(bufnr)
    if #wins > 0 then
      vim.api.nvim_set_current_win(wins[1])
      pcall(vim.cmd, 'startinsert')
    end
  end
  return true
end

--- Send a file reference like @path/to/file
function M.send_file_ref()
  local path = get_relative_file()
  if not path then
    vim.notify('No current file', vim.log.levels.WARN)
    return
  end
  M.send('@' .. path, { focus = true })
end

--- Send a range reference like @path/to/file:10-25 or @path/to/file:42 (single line collapsed)
--- Preferred: callers (the visual keymap) pass explicit start/end captured with
--- vim.fn.line("v") and vim.fn.line(".") while the selection is live.
--- When called without args it tries to detect a live visual selection first.
--- If start == end, the reference is collapsed to a single line (no "-N" suffix).
function M.send_range_ref(start_line, end_line)
  local path = get_relative_file()
  if not path then
    vim.notify('No current file', vim.log.levels.WARN)
    return
  end

  if not start_line or not end_line then
    -- When called without args (e.g. from :GrokSendRangeRef or other),
    -- try to capture the current visual selection if we're in one.
    local mode = vim.fn.mode()
    if mode:match('^[vV\x16]') then
      -- Live visual selection: 'v' is the other end, '.' is cursor.
      start_line = vim.fn.line('v')
      end_line = vim.fn.line('.')
    else
      -- Not in visual: fall back to last visual selection marks.
      -- These may be from a previous selection.
      start_line = vim.fn.line("'<")
      end_line = vim.fn.line("'>")

      if (not start_line or start_line == 0) and (not end_line or end_line == 0) then
        start_line = vim.fn.line('.')
        end_line = start_line
      end
    end
  end

  if not start_line or start_line == 0 then
    start_line = vim.fn.line('.')
    end_line = start_line
  end

  -- Ensure start <= end
  if end_line < start_line then
    start_line, end_line = end_line, start_line
  end

  -- Collapse to single-line format when range is only one line
  local ref
  if start_line == end_line then
    ref = string.format('@%s:%d', path, start_line)
  else
    ref = string.format('@%s:%d-%d', path, start_line, end_line)
  end
  M.send(ref, { focus = true })
end

--- Send current line reference @path:42
function M.send_line_ref()
  local l = vim.fn.line('.')
  local path = get_relative_file()
  if not path then
    vim.notify('No current file', vim.log.levels.WARN)
    return
  end
  M.send(string.format('@%s:%d', path, l), { focus = true })
end

--- Open a picker of ready-to-use actions / prompts (similar to opencode's select).
--- These are predefined prompts. We append relevant @file context and send to the grok terminal.
function M.select()
  local path = get_relative_file()
  local ref = path and ('@' .. path) or ''

  local items = {
    { label = 'Explain',          text = 'Explain this code and its context. Be thorough about the logic.' },
    { label = 'Fix issues',       text = 'Find and fix any bugs or problems in this code. Explain the fix.' },
    { label = 'Review',           text = 'Review this code for correctness, style, performance, and best practices.' },
    { label = 'Add tests',        text = 'Write good unit/integration tests for this code.' },
    { label = 'Optimize',         text = 'Optimize this code for performance and readability. Show before/after.' },
    { label = 'Document',         text = 'Add clear documentation, comments, and docstrings where missing.' },
    { label = 'Refactor',         text = 'Suggest a clean refactor of this code with explanations.' },
    { label = 'Find bugs',        text = 'Analyze for potential bugs, edge cases, and security issues.' },
    { label = 'Implement feature from comment', text = 'Implement the TODO or feature described in the code comments.' },
  }

  vim.ui.select(items, {
    prompt = 'Grok action (will be sent to terminal):',
    format_item = function(item) return item.label end,
  }, function(choice)
    if not choice then return end
    local prompt = choice.text
    if ref ~= '' then
      -- Prepend or append context reference so grok knows what we're talking about.
      prompt = prompt .. ' ' .. ref
    end
    -- Submit the full prompt
    M.send(prompt, { submit = true, focus = true })
  end)
end

-- Also expose a command-friendly version
M.send_prompt = function(prompt)
  if not prompt or prompt == '' then return end
  local path = get_relative_file()
  if path and not prompt:match('@') then
    prompt = prompt .. ' @' .. path
  end
  M.send(prompt, { submit = true, focus = true })
end

return M
