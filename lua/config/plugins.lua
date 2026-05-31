local M = {}

vim.api.nvim_create_autocmd('PackChanged', {
  group = vim.api.nvim_create_augroup('UserPackHooks', { clear = true }),
  callback = function(ev)
    local data = ev.data
    if not data or not data.spec or not data.kind then return end

    if data.spec.name == 'markdown-preview.nvim' and (data.kind == 'install' or data.kind == 'update') then
      vim.schedule(function()
        vim.notify('Building markdown-preview (yarn)...', vim.log.levels.INFO)
      end)
      vim.system({ 'sh', '-c', 'cd app && npx --yes yarn install' }, { cwd = data.path }, function(res)
        vim.schedule(function()
          if res.code == 0 then
            vim.notify('markdown-preview build complete', vim.log.levels.INFO)
          else
            vim.notify('markdown-preview build failed: ' .. (res.stderr or ''), vim.log.levels.ERROR)
          end
        end)
      end)
    end

    if data.spec.name == 'nvim-treesitter' and (data.kind == 'install' or data.kind == 'update') then
      vim.schedule(function()
        pcall(vim.cmd, 'TSUpdate')
      end)
    end

    if data.spec.name == 'sailfish' and (data.kind == 'install' or data.kind == 'update') then
      local rtp_path = vim.fs.joinpath(data.path, 'syntax', 'vim')
      if vim.uv.fs_stat(rtp_path) then
        vim.opt.rtp:append(rtp_path)
      end
    end
  end,
})

local plugins = {
  -- Core utilities
  'https://github.com/nvim-lua/plenary.nvim',
  'https://github.com/nvim-neotest/nvim-nio',

  -- UI / appearance
  'https://github.com/briones-gabriel/darcula-solid.nvim',
  'https://github.com/rktjmp/lush.nvim',
  'https://github.com/nvim-lualine/lualine.nvim',
  'https://github.com/nvim-tree/nvim-web-devicons',
  'https://github.com/echasnovski/mini.icons', -- helpful fallback / modern icon provider

  -- File explorer
  'https://github.com/nvim-tree/nvim-tree.lua',

  -- Treesitter (core + context + rainbow)
  'https://github.com/nvim-treesitter/nvim-treesitter',
  'https://github.com/nvim-treesitter/nvim-treesitter-context',
  'https://github.com/HiPhish/rainbow-delimiters.nvim',

  -- Telescope + extensions
  'https://github.com/nvim-telescope/telescope.nvim',
  'https://github.com/nvim-telescope/telescope-ui-select.nvim',
  'https://github.com/smartpde/telescope-recent-files',

  -- LSP + completion + snippets
  'https://github.com/neovim/nvim-lspconfig',
  'https://github.com/hrsh7th/nvim-cmp',
  'https://github.com/hrsh7th/cmp-nvim-lsp',
  'https://github.com/hrsh7th/cmp-buffer',
  'https://github.com/hrsh7th/cmp-path',
  'https://github.com/saadparwaiz1/cmp_luasnip',
  'https://github.com/L3MON4D3/LuaSnip',

  -- Mason (LSP/DAP/linter management)
  'https://github.com/williamboman/mason.nvim',
  'https://github.com/williamboman/mason-lspconfig.nvim',

  -- Language specific / heavy plugins
  'https://github.com/mrcjkb/rustaceanvim',
  'https://github.com/ray-x/go.nvim',
  'https://github.com/ray-x/guihua.lua',
  'https://github.com/saecki/crates.nvim',

  -- DAP
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/rcarriga/nvim-dap-ui',

  -- Git
  'https://github.com/tpope/vim-fugitive',
  'https://github.com/rbong/vim-flog',
  'https://github.com/sindrets/diffview.nvim',
  'https://github.com/lewis6991/gitsigns.nvim',
  'https://github.com/f-person/git-blame.nvim',

  -- Editing / productivity
  'https://github.com/numToStr/Comment.nvim',
  'https://github.com/windwp/nvim-autopairs',
  'https://github.com/junegunn/vim-easy-align',
  'https://github.com/kshenoy/vim-signature',
  'https://github.com/pocco81/AutoSave.nvim',
  'https://github.com/rmagatti/auto-session',
  'https://github.com/LunarVim/bigfile.nvim',
  'https://github.com/uga-rosa/translate.nvim',
  'https://github.com/tpope/vim-sleuth',
  'https://github.com/MunifTanjim/prettier.nvim',

  -- Database
  'https://github.com/tpope/vim-dadbod',
  'https://github.com/kristijanhusak/vim-dadbod-ui',
  'https://github.com/kristijanhusak/vim-dadbod-completion',

  -- Folding
  'https://github.com/kevinhwang91/nvim-ufo',
  'https://github.com/kevinhwang91/promise-async',

  -- Other tools
  'https://github.com/f-person/auto-dark-mode.nvim',
  'https://github.com/aveplen/ruscmd.nvim',
  'https://github.com/NickvanDyke/opencode.nvim',
  'https://github.com/folke/snacks.nvim',
  'https://gitlab.com/itaranto/plantuml.nvim',
  'https://github.com/junegunn/vim-github-dashboard',
  'https://github.com/iamcco/markdown-preview.nvim',
  'https://github.com/paval-shlyk/session-todo.nvim',
  'https://github.com/paval-shlyk/dev-tools.nvim',
  'https://github.com/greggh/claude-code.nvim',
  'https://github.com/rust-sailfish/sailfish',
  'https://github.com/kenn7/vim-arsync',
  'https://github.com/prabirshrestha/async.vim',

  -- Misc
  'https://github.com/kristijanhusak/vim-dadbod-completion', -- (dedup handled by vim.pack)
}

-- Convert simple strings to full spec tables for clarity and future extensibility.
local specs = {}
for _, p in ipairs(plugins) do
  if type(p) == 'string' then
    table.insert(specs, { src = p })
  else
    table.insert(specs, p)
  end
end

-- Perform the actual plugin installation / registration.
-- This replaces the entire old vim-plug block.
vim.pack.add(specs)

pcall(function()
  local devicons = require('nvim-web-devicons')
  devicons.setup({ default = true })

  -- Explicit yaml/yml support (in case default set is incomplete)
  devicons.set_icon {
    yml = { icon = "", color = "#6d8086", cterm_color = "66", name = "Yml" },
    yaml = { icon = "", color = "#6d8086", cterm_color = "66", name = "Yaml" },
  }

  vim.g.have_nerd_font = true
end)

pcall(function()
  require('mini.icons').setup()
end)

M.specs = specs
return M
