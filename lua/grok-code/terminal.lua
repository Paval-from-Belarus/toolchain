local M = {}

M.terminal = {
  instances = {},
  saved_updatetime = nil,
  current_instance = nil,
}

local function get_instance_identifier(git)
  local git_root = git.get_git_root()
  return git_root or vim.fn.getcwd()
end

local function calculate_float_dimension(value, max_value)
  if value == nil then
    return math.floor(max_value * 0.8)
  elseif type(value) == 'string' and value:match('^%d+%%$') then
    local p = tonumber(value:match('^(%d+)%%$'))
    return math.floor(max_value * p / 100)
  end
  return value
end

local function calculate_float_position(value, window_size, max_value)
  local pos
  if value == 'center' then
    pos = math.floor((max_value - window_size) / 2)
  elseif type(value) == 'string' and value:match('^%d+%%$') then
    local p = tonumber(value:match('^(%d+)%%$'))
    pos = math.floor(max_value * p / 100)
  else
    pos = value or 0
  end
  return math.max(0, math.min(pos, max_value - window_size))
end

local function create_float(config, existing_bufnr)
  local fc = config.window.float or {}
  local ew, eh = vim.o.columns, vim.o.lines - vim.o.cmdheight - 1

  local w = calculate_float_dimension(fc.width, ew)
  local h = calculate_float_dimension(fc.height, eh)
  local r = calculate_float_position(fc.row, h, eh)
  local c = calculate_float_position(fc.col, w, ew)

  local win_config = {
    relative = fc.relative or 'editor',
    width = w, height = h, row = r, col = c,
    border = fc.border or 'rounded',
    style = 'minimal',
  }

  local bufnr = existing_bufnr
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then
    bufnr = vim.api.nvim_create_buf(false, true)
  end

  return vim.api.nvim_open_win(bufnr, true, win_config)
end

local function build_command_with_git_root(config, git, base_cmd)
  if config.git and config.git.use_git_root then
    local root = git.get_git_root()
    if root then
      local q = vim.fn.shellescape(root)
      local sep = config.shell.separator
      return string.format('%s %s %s %s %s %s',
        config.shell.pushd_cmd, q, sep, base_cmd, sep, config.shell.popd_cmd)
    end
  end
  return base_cmd
end

local function configure_window_options(win_id, config)
  if config.window.hide_numbers then
    vim.api.nvim_set_option_value('number', false, { win = win_id })
    vim.api.nvim_set_option_value('relativenumber', false, { win = win_id })
  end
  if config.window.hide_signcolumn then
    vim.api.nvim_set_option_value('signcolumn', 'no', { win = win_id })
  end
end

local function generate_buffer_name(instance_id, _config)
  return 'grok-code-' .. instance_id:gsub('[^%w%-_]', '-')
end

local function create_split(position, config, existing_bufnr)
  if position == 'float' then
    return create_float(config, existing_bufnr)
  end
  local is_vertical = position:match('vsplit') or position:match('vertical')
  if position:match('split') then
    vim.cmd(position)
  else
    vim.cmd((is_vertical and 'vsplit' or 'split'))
  end
  if existing_bufnr then
    vim.cmd('buffer ' .. existing_bufnr)
  end
  if is_vertical then
    vim.cmd('vertical resize ' .. math.floor(vim.o.columns * config.window.split_ratio))
  else
    vim.cmd('resize ' .. math.floor(vim.o.lines * config.window.split_ratio))
  end
end

function M.force_insert_mode(grok_code, config)
  local cur = vim.fn.bufnr('%')
  local is_instance = false
  for _, b in pairs(grok_code.grok_code.instances) do
    if b == cur and vim.api.nvim_buf_is_valid(b) then is_instance = true break end
  end
  if is_instance and not config.window.start_in_normal_mode then
    if vim.bo.buftype == 'terminal' then
      vim.cmd('silent! stopinsert')
      vim.schedule(function() vim.cmd('silent! startinsert') end)
    end
  end
end

local function is_valid_terminal_buffer(bufnr)
  if not bufnr or not vim.api.nvim_buf_is_valid(bufnr) then return false end
  local bt = vim.api.nvim_get_option_value('buftype', { buf = bufnr })
  local job = vim.b[bufnr] and vim.b[bufnr].terminal_job_id
  if bt ~= 'terminal' or not job then return false end
  return vim.fn.jobwait({ job }, 0)[1] == -1
end

local function handle_existing_instance(bufnr, config)
  local wins = vim.fn.win_findbuf(bufnr)
  if #wins > 0 then
    for _, w in ipairs(wins) do vim.api.nvim_win_close(w, true) end
  else
    if config.window.position == 'float' then
      create_float(config, bufnr)
    else
      create_split(config.window.position, config, bufnr)
    end
    if not config.window.start_in_normal_mode then
      vim.schedule(function() vim.cmd('stopinsert | startinsert') end)
    end
  end
end

--- Show friendly install prompt when `grok` binary is missing.
local function show_install_prompt(config)
  local inst = config.install or {}
  local lines = {
    'Grok Build CLI (grok) not found.',
    '',
    'Install with:',
    '  ' .. (inst.command or 'curl -fsSL https://x.ai/cli/install.sh | bash'),
    '',
    'Official documentation:',
    '  ' .. (inst.url or 'https://x.ai/cli'),
  }
  if inst.note then
    table.insert(lines, '')
    table.insert(lines, inst.note)
  end

  -- Try to use a nice floating window
  local ok, _ = pcall(function()
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.api.nvim_set_option_value('buftype', 'nofile', { buf = buf })
    vim.api.nvim_set_option_value('bufhidden', 'wipe', { buf = buf })
    vim.api.nvim_set_option_value('filetype', 'markdown', { buf = buf })

    local w = math.max(60, math.min(80, vim.o.columns - 10))
    local h = #lines + 2
    local win = vim.api.nvim_open_win(buf, true, {
      relative = 'editor',
      width = w,
      height = h,
      row = math.floor((vim.o.lines - h) / 2),
      col = math.floor((vim.o.columns - w) / 2),
      border = 'rounded',
      style = 'minimal',
      title = ' Install Grok Build ',
      title_pos = 'center',
    })
    vim.api.nvim_buf_set_keymap(buf, 'n', 'q', '<cmd>close<CR>', { noremap = true, silent = true })
    vim.api.nvim_buf_set_keymap(buf, 'n', '<Esc>', '<cmd>close<CR>', { noremap = true, silent = true })
    vim.api.nvim_set_option_value('modifiable', false, { buf = buf })
  end)

  if not ok then
    vim.notify(table.concat(lines, '\n'), vim.log.levels.WARN)
  end
end

-- Exposed so other code (e.g. raw :Grok command) can call the same nice prompt
M.show_install_prompt = show_install_prompt

local function get_instance_id(config, git)
  if config.git.multi_instance then
    return get_instance_identifier(git)
  end
  return 'global'
end

local function create_new_instance(grok_code, config, git, instance_id, extra_args)
  -- Always resolve/check the bare binary; extra_args (e.g. --continue) are appended later.
  local base_cmd = config.command
  local function ensure_grok_available()
    if vim.fn.executable(base_cmd) == 1 then return true end
    -- Common install locations for Grok Build
    local candidates = {
      vim.fn.expand('~/.grok/bin/grok'),
      vim.fn.expand('~/.local/bin/grok'),
      '/usr/local/bin/grok',
    }
    for _, p in ipairs(candidates) do
      if vim.fn.executable(p) == 1 or (vim.fn.filereadable(p) == 1 and vim.fn.getfperm(p):match('x')) then
        -- If found but not in PATH, we still allow launch via full path in this session
        -- (termopen will work with absolute path)
        config._resolved_command = p
        return true
      end
    end
    return false
  end

  if not ensure_grok_available() then
    show_install_prompt(config)
    return
  end

  local binary = config._resolved_command or base_cmd
  local to_run = binary
  if extra_args and extra_args ~= '' then
    to_run = binary .. ' ' .. extra_args
  end

  local full_cmd = build_command_with_git_root(config, git, to_run)

  if config.window.position == 'float' then
    local buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_set_option_value('bufhidden', 'hide', { buf = buf })
    local win = create_float(config, buf)
    vim.api.nvim_win_set_buf(win, buf)

    vim.fn.termopen(full_cmd)

    vim.api.nvim_buf_set_name(buf, generate_buffer_name(instance_id, config))
    configure_window_options(win, config)
    grok_code.grok_code.instances[instance_id] = buf

    if config.window.enter_insert and not config.window.start_in_normal_mode then
      vim.cmd('startinsert')
    end
  else
    create_split(config.window.position, config)
    vim.cmd('terminal ' .. full_cmd)
    vim.cmd('setlocal bufhidden=hide')
    vim.cmd('file ' .. generate_buffer_name(instance_id, config))

    local curwin = vim.api.nvim_get_current_win()
    configure_window_options(curwin, config)

    grok_code.grok_code.instances[instance_id] = vim.fn.bufnr('%')

    if config.window.enter_insert and not config.window.start_in_normal_mode then
      vim.cmd('startinsert')
    end
  end
end

function M.toggle(grok_code, config, git, extra_args)
  local id = get_instance_id(config, git)
  grok_code.grok_code.current_instance = id

  local bufnr = grok_code.grok_code.instances[id]

  if bufnr and not is_valid_terminal_buffer(bufnr) then
    for _, w in ipairs(vim.fn.win_findbuf(bufnr)) do pcall(vim.api.nvim_win_close, w, true) end
    pcall(vim.api.nvim_buf_delete, bufnr, { force = true })
    grok_code.grok_code.instances[id] = nil
    bufnr = nil
  end

  if bufnr and vim.api.nvim_buf_is_valid(bufnr) then
    handle_existing_instance(bufnr, config)
  else
    create_new_instance(grok_code, config, git, id, extra_args)
  end
end

return M
