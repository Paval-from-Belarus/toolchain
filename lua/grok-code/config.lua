---@mod grok-code.config Configuration management for grok-code.nvim
---@brief [[
--- Configuration for Grok Build (grok) integration in Neovim.
--- Mirrors the structure of claude-code.nvim for consistent interface.
---@brief ]]

local M = {}

--- Default configuration options (adapted for grok)
--- @type table
M.default_config = {
  -- Terminal window settings (same semantics as claude-code.nvim)
  window = {
    split_ratio = 0.35,
    -- 'botright vsplit' opens a vertical split on the right side (good for AI agent side panel)
    position = 'botright vsplit',
    enter_insert = true,
    start_in_normal_mode = false,
    hide_numbers = true,
    hide_signcolumn = true,
    float = {
      width = '85%',
      height = '80%',
      row = 'center',
      col = 'center',
      relative = 'editor',
      border = 'rounded',
    },
  },
  -- File refresh settings
  refresh = {
    enable = true,
    updatetime = 100,
    timer_interval = 1200,
    show_notifications = true,
  },
  -- Git integration
  git = {
    use_git_root = true,
    multi_instance = true,
  },
  -- Shell
  shell = {
    separator = '&&',
    pushd_cmd = 'pushd',
    popd_cmd = 'popd',
  },
  -- The binary
  command = 'grok',
  -- Supported variants (from `grok --help`)
  command_variants = {
    continue = '--continue',
    resume = '--resume',
    -- You can add more e.g. plan mode etc if desired
  },
  -- Keymaps (chosen to be similar but not conflict with claude-code's <C-,>)
  keymaps = {
    toggle = {
      normal = '<C-.>',      -- Consistent "AI companion" toggle feel
      terminal = '<C-.>',
      variants = {
        continue = '<leader>gC',
        resume = '<leader>gR',
      },
    },

    -- Context sending actions (for sending file/range references to the grok terminal)
    -- Set to false to disable a particular binding.
    send_file_ref = '<leader>a',   -- normal mode: send @file
    send_range_ref = '<leader>l',  -- visual mode: send @file:start-end (collapsed to @file:N if single line)
    send_line_ref = '<leader>l',   -- normal mode: send @file:line
    select = '<leader>s',          -- picker of ready-to-use prompts/actions
  },

  -- Install instructions (used when `grok` is missing)
  install = {
    url = 'https://x.ai/cli',
    command = 'curl -fsSL https://x.ai/cli/install.sh | bash',
    note = 'Grok Build is available to SuperGrok and X Premium Plus subscribers.',
  },
}

local function validate_window_config(window)
  if type(window) ~= 'table' then return false, 'window must be a table' end
  if type(window.split_ratio) ~= 'number' or window.split_ratio <= 0 or window.split_ratio > 1 then
    return false, 'window.split_ratio must be number between 0 and 1'
  end
  if type(window.position) ~= 'string' then return false, 'window.position required' end
  if type(window.enter_insert) ~= 'boolean' then return false, 'window.enter_insert must be boolean' end
  if type(window.start_in_normal_mode) ~= 'boolean' then return false, 'window.start_in_normal_mode must be boolean' end
  if type(window.hide_numbers) ~= 'boolean' then return false, 'window.hide_numbers must be boolean' end
  if type(window.hide_signcolumn) ~= 'boolean' then return false, 'window.hide_signcolumn must be boolean' end
  return true
end

local function validate_float(float)
  if type(float) ~= 'table' then return false, 'float config required when position=float' end
  -- Accept number or "NN%"
  local function ok_dim(v)
    if type(v) == 'number' and v > 0 then return true end
    if type(v) == 'string' and v:match('^%d+%%$') then return true end
    return false
  end
  if not ok_dim(float.width) then return false, 'float.width must be positive number or "NN%"' end
  if not ok_dim(float.height) then return false, 'float.height must be positive number or "NN%"' end
  if float.relative ~= 'editor' and float.relative ~= 'cursor' then
    return false, 'float.relative must be "editor" or "cursor"'
  end
  return true
end

local function validate_config(cfg)
  local ok, err = validate_window_config(cfg.window)
  if not ok then return false, err end
  if cfg.window.position == 'float' then
    ok, err = validate_float(cfg.window.float)
    if not ok then return false, err end
  end
  if type(cfg.command) ~= 'string' then return false, 'command must be string' end
  if type(cfg.command_variants) ~= 'table' then return false, 'command_variants must be table' end
  return true
end

function M.parse_config(user_config, silent)
  local cfg = vim.tbl_deep_extend('force', {}, M.default_config, user_config or {})

  if cfg.window.position == 'float' and not (user_config and user_config.window and user_config.window.float) then
    cfg.window.float = vim.deepcopy(M.default_config.window.float)
  end

  local ok, err = validate_config(cfg)
  if not ok then
    if not silent then
      vim.notify('grok-code: ' .. err, vim.log.levels.ERROR)
    end
    return vim.deepcopy(M.default_config)
  end
  return cfg
end

return M
