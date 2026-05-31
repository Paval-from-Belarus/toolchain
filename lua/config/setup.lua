vim.g.mapleader = ' '

local opts = { noremap = true, silent = true }

require('Comment').setup {
  mappings = {
    basic = true,
    extra = true,
  },
}

vim.keymap.set('v', '<S-Tab>', '<gv', { noremap = true, silent = true })
vim.keymap.set('v', '<Tab>', '>gv', { noremap = true, silent = true })

vim.keymap.set('n', 'cvi', ':Inspect<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '=', ':horizontal split<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '+', ':vertical split<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-Left>', ':tabprevious<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<M-Right>', ':tabnext<CR>', { noremap = true, silent = true })

vim.keymap.set('n', '<C-F8>', ':DapToggleBreakpoint<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<F7>', ':DapStepInto<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<F8>', ':DapStepOver<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<F9>', ':DapContinue<CR>', { noremap = true, silent = true })
vim.keymap.set('n', '<C-F9>', ':RustRun<CR>', { noremap = true, silent = true })

vim.keymap.set('n', 'псс', 'gcc', { remap = true, silent = true })

local function show_documentation()
  local filetype = vim.bo.filetype
  local word = vim.fn.expand('<cword>')

  if filetype == 'vim' or filetype == 'help' then
    vim.cmd('rightbelow vert h ' .. word)
  elseif filetype == 'man' or filetype == 'just' then
    vim.cmd('rightbelow vert Man ' .. word)
  elseif vim.fn.expand('%:t') == 'Cargo.toml' then
    local ok, crates = pcall(require, 'crates')
    if ok and crates.popup_available() then
      crates.show_popup()
      return
    end
  end

  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if #clients > 0 then
    vim.lsp.buf.hover()
  else
    vim.notify("No LSP or documentation available", vim.log.levels.INFO)
  end
end

vim.keymap.set('n', '<C-F12>', require('telescope.builtin').lsp_document_symbols, {})
vim.keymap.set('n', 'cve', require('telescope.builtin').find_files, {})
vim.keymap.set('n', 'cvf', require('telescope.builtin').live_grep, {})
vim.keymap.set('n', 'cvq', require('telescope.builtin').quickfix, {})
vim.keymap.set('n', 'gr', require('telescope.builtin').lsp_references, {})

vim.keymap.set('n', '<leader>ci', require('telescope.builtin').lsp_incoming_calls, {})
vim.keymap.set('n', '<leader>co', require('telescope.builtin').lsp_outgoing_calls, {})

vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

vim.keymap.set('n', 'c]', function() require('treesitter-context').go_to_context(vim.v.count1) end, { silent = true })

local diffview_state = 0
local diffview_history_state = 0

local function diffview_toggle()
  if diffview_history_state == 1 then
    diffview_history_state = 0
    pcall(vim.cmd, "DiffviewClose")
  end
  if diffview_state == 0 then
    diffview_state = 1
    vim.cmd("DiffviewOpen")
  else
    diffview_state = 0
    pcall(vim.cmd, "DiffviewClose")
  end
end

local function diffview_history_toggle()
  if diffview_state == 1 then
    diffview_state = 0
    pcall(vim.cmd, "DiffviewClose")
  end
  if diffview_history_state == 0 then
    diffview_history_state = 1
    vim.cmd("DiffviewFileHistory --follow")
  else
    diffview_history_state = 0
    pcall(vim.cmd, "DiffviewClose")
  end
end

vim.keymap.set('n', '<M-0>', diffview_toggle)
vim.keymap.set('n', '<M-9>', diffview_history_toggle)

vim.keymap.set('n', '<M-5>', function() require('dapui').toggle() end, { silent = true })
vim.keymap.set('n', '<C-F2>', function() vim.cmd('DapTerminate') end, { silent = true })

vim.keymap.set('n', '<S-F9>', function() vim.cmd('RustLsp debuggables') end, { silent = true })

vim.keymap.set('n', '<C-e>', function() require('telescope').extensions.recent_files.pick() end, { noremap = true, silent = true })

vim.keymap.set('n', 'cvx', ':Telescope session-lens<CR>', {})
vim.keymap.set('n', 'cvr', function()
  local find = vim.fn.input('Find: ')
  if find == '' then return end
  local replace = vim.fn.input('Replace with: ')
  if replace == '' then return end
  local esc_find = vim.fn.escape(find, '/')
  local esc_replace = vim.fn.escape(replace, '/')
  require('telescope.builtin').live_grep({
    default_text = find,
  })
end, { desc = 'Search and replace across project' })

vim.keymap.set({ 'n', 'x' }, '<leader>a', function() require('opencode').ask('@this: ', { submit = true }) end, { desc = 'Ask opencode' })
vim.keymap.set({ 'n', 'x' }, '<leader>s', function() require('opencode').select() end, { desc = 'Execute opencode action' })
vim.keymap.set('n', '<leader>l', function() return require('opencode').operator('@this ') .. '_' end, { desc = 'Add line to opencode', expr = true })
vim.keymap.set({ 'n', 't' }, 'cva', function() require('opencode').toggle() end, { desc = 'Toggle opencode' })

vim.keymap.set({ 'n', 't' }, '<M-F12>', function()
  local current_win = vim.api.nvim_get_current_win()
  local current_buf = vim.api.nvim_win_get_buf(current_win)
  local current_buftype = vim.api.nvim_buf_get_option(current_buf, 'buftype')
  if current_buftype == 'terminal' then
    vim.cmd('wincmd p')
  else
    for _, win in ipairs(vim.api.nvim_list_wins()) do
      local buf = vim.api.nvim_win_get_buf(win)
      if vim.api.nvim_buf_get_option(buf, 'buftype') == 'terminal' then
        vim.api.nvim_set_current_win(win)
        vim.cmd('startinsert')
        return
      end
    end
  end
end, { noremap = true, silent = true })

vim.keymap.set({ 'n', 't' }, '<F5>', function()
  vim.fn.system('tmux resize-pane -D 1 && tmux resize-pane -U 1')
end)

vim.keymap.set('n', '<M-CR>', function() vim.lsp.buf.code_action() end, { silent = true })
vim.keymap.set('v', '<M-CR>', function() vim.lsp.buf.code_action() end, { silent = true })

vim.keymap.set('n', '<F4>', function()
  local api = require('nvim-tree.api')
  if api.tree.is_visible() then api.tree.close() else vim.cmd('DBUI') end
end, { desc = 'Toggle DBUI / tree' })

vim.keymap.set('n', '<M-1>', function()
  local api = require('nvim-tree.api')
  if api.tree.is_visible() then api.tree.close() else api.tree.open() end
end, { noremap = true, silent = true })

vim.keymap.set('n', '<M-F1>', function()
  local api = require('nvim-tree.api')
  if api.tree.is_visible() then api.tree.focus() else api.tree.open(); api.tree.focus() end
end, { noremap = true, silent = true })

vim.keymap.set('n', '<C-M-p>', [[<cmd>horizontal resize -2<cr>]])
vim.keymap.set('n', 'cvd', [[<cmd>horizontal resize +2<cr>]])
vim.keymap.set('n', '<C-M-[>', [[<cmd>vertical resize -5<cr>]])
vim.keymap.set('n', '<C-M-]>', [[<cmd>vertical resize +5<cr>]])

vim.keymap.set('n', '<C-Tab>', function() vim.cmd('wincmd w') end, { noremap = true, silent = true })
vim.keymap.set('n', '<Tab>', function() vim.cmd('wincmd w') end, { noremap = true, silent = true })

vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', { expr = true, replace_keycodes = false })

-- === Complex plugin configuration below ===

require('go').setup()

local vim = vim

require('auto-dark-mode').setup({
	set_dark_mode = function()
		vim.cmd("colorscheme darcula-solid-idea")
	end,
	set_light_mode = function()
		vim.cmd("colorscheme zellner")
	end,
	update_interval = 3000,
	fallback = "dark"
})

vim.cmd("colorscheme darcula-solid-idea")

ts_context = require 'treesitter-context'
ts_context.setup {
	enable = true,     -- Enable this plugin (Can be enabled/disabled later via commands)
	multiwindow = false, -- Enable multiwindow support.
	max_lines = 5,     -- How many lines the window should span. Values <= 0 mean no limit.
	min_window_height = 0, -- Minimum editor window height to enable context. Values <= 0 mean no limit.
	line_numbers = true,
	multiline_threshold = 10, -- Maximum number of lines to show for a single context
	trim_scope = 'outer', -- Which context lines to discard if `max_lines` is exceeded. Choices: 'inner', 'outer'
	mode = 'cursor',   -- Line used to calculate context. Choices: 'cursor', 'topline'
	-- Separator between context and content. Should be a single character string, like '-'.
	-- When separator is set, the context will only show up when there are at least 2 lines above cursorline.
	separator = nil,
	zindex = 20, -- The Z-index of the context window
	on_attach = nil, -- (fun(buf: integer): boolean) return false to disable attaching
}

-- Comment setup moved to plugin/keymap.lua for centralized keymaps
vim.g.mapleader = ' '
local rainbow_delimiters = require 'rainbow-delimiters'

---@type rainbow_delimiters.config
vim.g.rainbow_delimiters = {
	strategy = {
		[''] = rainbow_delimiters.strategy['global'],
		vim = rainbow_delimiters.strategy['local'],
	},
	query = {
		[''] = 'rainbow-delimiters',
		lua = 'rainbow-blocks',
	},
	priority = {
		[''] = 110,
		lua = 210,
	},
	highlight = {
		'RainbowDelimiterRed',
		'RainbowDelimiterYellow',
		'RainbowDelimiterBlue',
		'RainbowDelimiterOrange',
		'RainbowDelimiterGreen',
		'RainbowDelimiterViolet',
		'RainbowDelimiterCyan',
	},
}
vim.keymap.set("n", "<C-M-p>", [[<cmd>horizontal resize -2<cr>]]) -- make the window biger vertically
vim.keymap.set("n", "cvd", [[<cmd>horizontal resize +2<cr>]])     -- make the window smaller vertically
vim.keymap.set("n", "<C-M-[>", [[<cmd>vertical resize -5<cr>]])   -- make the window bigger horizontally by pressing shift and =
vim.keymap.set("n", "<C-M-]>", [[<cmd>vertical resize +5<cr>]])   -- make the window smaller horizontally by pressing shift and -

local function is_documentation_float_open()
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local config = vim.api.nvim_win_get_config(win)
		-- Check if the window is a floating window (relative is non-empty)
		if config.relative ~= "" then
			local buf = vim.api.nvim_win_get_buf(win)
			local buf_filetype = vim.api.nvim_buf_get_option(buf, "filetype")

			-- Only return true for markdown documentation windows
			if buf_filetype == "markdown" or buf_filetype == "crates.nvim" then
				return true, win
			end
		end
	end
	return false, nil
end

-- vim.keymap.set("n", "<TAB>", "<C-W><C-W>")

-- Alternative navigation for when TAB is bound by OpenCode
vim.keymap.set("n", "<C-Tab>", function()
	if is_float_open() then
		-- Focus the floating window
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local config = vim.api.nvim_win_get_config(win)
			if config.relative ~= "" then
				vim.api.nvim_set_current_win(win)
				return
			end
		end
	else
		-- Check if current window is a terminal and switch to next window
		local current_win = vim.api.nvim_get_current_win()
		local current_buf = vim.api.nvim_win_get_buf(current_win)
		local current_buftype = vim.api.nvim_buf_get_option(current_buf, "buftype")

		if current_buftype == "terminal" then
			-- If in terminal, switch to next window
			vim.cmd("wincmd w")
		else
			-- Check if there are any terminal windows open
			local terminal_found = false
			for _, win in ipairs(vim.api.nvim_list_wins()) do
				local buf = vim.api.nvim_win_get_buf(win)
				local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
				if buftype == "terminal" then
					terminal_found = true
					break
				end
			end

			if terminal_found then
				-- If terminals exist, cycle through all windows including terminals
				vim.cmd("wincmd w")
			else
				-- No terminals, just switch to next panel
				vim.cmd("wincmd w")
			end
		end
	end
end, { noremap = true, silent = true })

-- Original TAB mapping (may be overridden by OpenCode)
vim.keymap.set("n", "<Tab>", function()
	local float_is_open = is_documentation_float_open()
	if float_is_open then
		-- Focus the floating window
		for _, win in ipairs(vim.api.nvim_list_wins()) do
			local config = vim.api.nvim_win_get_config(win)
			if config.relative ~= "" then
				vim.api.nvim_set_current_win(win)
				return
			end
		end
	else
		-- Switch to next panel, skipping terminal and floating windows
		local current_win = vim.api.nvim_get_current_win()
		local all_windows = vim.api.nvim_list_wins()

		-- Filter to only real (non-floating) windows
		local real_windows = {}
		for _, win in ipairs(all_windows) do
			local config = vim.api.nvim_win_get_config(win)
			if config.relative == "" then -- Only real windows (not floating)
				table.insert(real_windows, win)
			end
		end

		-- Find current window index in real windows
		local current_idx = 0
		for i, win in ipairs(real_windows) do
			if win == current_win then
				current_idx = i
				break
			end
		end

		-- Find next non-terminal real window
		for i = 1, #real_windows do
			local next_idx = (current_idx + i - 1) % #real_windows + 1
			local next_win = real_windows[next_idx]

			-- Skip current window
			if next_win ~= current_win then
				local buf = vim.api.nvim_win_get_buf(next_win)
				local buftype = vim.api.nvim_buf_get_option(buf, "buftype")

				-- If not a terminal, switch to it
				if buftype ~= "terminal" then
					vim.api.nvim_set_current_win(next_win)
					return
				end
			end
		end
	end
end, { noremap = true, silent = true })



vim.keymap.set("n", "<M-5>", function()
		-- local widgets = require('dapui')
		-- local sidebar = widgets.sidebar(widgets.scopes)
		-- sidebar.open()
		require("dapui").toggle()
	end,
	opts)

local is_debug_enabled = false
-- vim.keymap.set("n", "<S-F9>", function()
--         is_debug_enabled = not is_debug_enabled
--         vim.cmd (":RustLsp debuggables<CR>")
-- end,
-- opts)
vim.api.nvim_set_keymap('n', '<S-F9>', '', {
	noremap = true,
	silent = true,
	callback = function()
		-- Custom logic for debugging tests
		vim.cmd(':RustLsp debuggables')
		-- Additional custom logic here if needed
	end
})

vim.keymap.set("n", "<C-F2>", function()
		is_debug_enabled = false
		vim.cmd("DapTerminate")
	end,
	opts)


require('lsp_config')
require("nvim-autopairs").setup {}
require('mason').setup({
	ui = {
		icons = {
			package_installed = "✓",
			package_pending = "➜",
			package_uninstalled = "✗"
		}
	}
})

vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1
vim.opt.termguicolors = true
local nvim_tree_attach = function(bufnr)
	local api = require "nvim-tree.api"

	local function opts(desc)
		return { desc = "nvim-tree: " .. desc, buffer = bufnr, noremap = true, silent = true, nowait = true,
		}
	end

	vim.keymap.set('n', ' ', api.tree.change_root_to_node, opts('CD'))
	vim.keymap.set('n', '<C-PageUp>', api.tree.change_root_to_parent, opts('Up'))
	-- default mappings
	api.config.mappings.default_on_attach(bufnr)
	vim.keymap.del('n', '<Tab>', { buffer = bufnr })
	-- custom mappings
	--       vim.keymap.set('n', '?',     api.tree.toggle_help,                  opts('Help'))
end
-- OR setup with some options
require("nvim-tree").setup({
	update_focused_file = {
		enable = true
	},
	sort = {
		sorter = "case_sensitive",
	},
	view = {
		width = 30,
	},
	renderer = {
		group_empty = true,
	},
	filters = {
		dotfiles = true,
	},
	on_attach = nvim_tree_attach
})

vim.keymap.set('n', 'K', show_documentation, { silent = true })

vim.keymap.set("n", "<S-F6>", function() vim.lsp.buf.rename() end, opts)

vim.keymap.set("n", "<C-M-l>", function() vim.lsp.buf.format() end, { desc = "Format buffer", })
vim.keymap.set("n", "g]", function() vim.lsp.buf.implementation() end, { desc = "Go to implementation of chosen one", })
vim.keymap.set("n", "gd", function() vim.lsp.buf.definition() end, { desc = "Go to definition", })

vim.keymap.set("n", "<F2>", function() vim.diagnostic.jump({ count = 1, float = true }) end, opts)
vim.keymap.set("n", "<S-F2>", function() vim.diagnostic.jump({ count = -1, float = true }) end, opts)

require("telescope").load_extension("recent_files")
local crates = require('crates')

vim.api.nvim_set_keymap("n", "<C-e>",
	[[<cmd>lua require('telescope').extensions.recent_files.pick()<CR>]],
	{ noremap = true, silent = true })

local builtin = require('telescope.builtin')
local workspace_symbols_opt = {
	symbols = {
		"interface",
		"class",
		"struct"
	}
}
--builtin.lsp_workspace_symbols(workspace_symbols_opt)
vim.keymap.set('n', '<C-F12>', builtin.lsp_document_symbols, {})
-- vim.keymap.set('n', 'cvi', builtin.lsp_workspace_symbols, {})
vim.keymap.set('n', 'cve', builtin.find_files, {})
vim.keymap.set('n', 'cvf', builtin.live_grep, {})
vim.keymap.set('n', 'cvq', builtin.quickfix, {})
vim.keymap.set('n', 'cvo', crates.show_features_popup, {})
vim.keymap.set('n', 'gr', builtin.lsp_references, {})

vim.keymap.set('n', '<leader>ci', builtin.lsp_incoming_calls, {})
vim.keymap.set('n', '<leader>co', builtin.lsp_outgoing_calls, {})

vim.o.foldcolumn = '0' -- '0' is not bad
vim.o.foldlevel = 99   -- Using ufo provider need a large value, feel free to decrease the value
vim.o.foldlevelstart = 99
vim.o.foldenable = true

vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

require('ufo').setup({
	provider_selector = function(bufnr, filetype, buftype)
		return { 'treesitter', 'indent' }
	end
})
require('auto-save').setup({
	execution_message = {
		message = function()
			return ''
		end,
	}
})

require('dapui').setup({
	controls = {
		element = "repl",
		enabled = true,
		icons = {
			disconnect = "",
			pause = "",
			play = "",
			run_last = "",
			step_back = "",
			step_into = "",
			step_out = "",
			step_over = "",
			terminate = ""
		}
	},
	element_mappings = {},
	expand_lines = true,
	floating = {
		border = "single",
		mappings = {
			close = { "q", "<Esc>" }
		}
	},
	force_buffers = true,
	icons = {
		collapsed = "",
		current_frame = "",
		expanded = ""
	},
	layouts = { {
		elements = { {
			id = "scopes",
			size = 0.25
		}, {
			id = "breakpoints",
			size = 0.25
		}, {
			id = "stacks",
			size = 0.25
		}, {
			id = "watches",
			size = 0.25
		} },
		position = "left",
		size = 40
	}, {
		elements = { {
			id = "repl",
			size = 0.5
		}, {
			id = "console",
			size = 0.5
		} },
		position = "bottom",
		size = 10
	} },
	mappings = {
		edit = "e",
		expand = { "<CR>", "<2-LeftMouse>" },
		open = "o",
		remove = "d",
		repl = "r",
		toggle = "t"
	},
	render = {
		indent = 1,
		max_value_lines = 100
	}
})
--
-- vim.keymap.set("n", "<C-M-o>", function() vim.lsp.buf.format() end, { desc = "Remove unused import", })
-- vim.keymap.set(
-- 	{ "n", "o", "x" },
-- 	"w",
-- 	"<cmd>lua require('spider').motion('w')<CR>",
-- 	{ desc = "Spider-w" }
-- )
-- vim.keymap.set(
-- 	{ "n", "o", "x" },
-- 	"e",
-- 	"<cmd>lua require('spider').motion('e')<CR>",
-- 	{ desc = "Spider-e" }
-- )
-- vim.keymap.set(
-- 	{ "n", "o", "x" },
-- 	"b",
-- 	"<cmd>lua require('spider').motion('b')<CR>",
-- 	{ desc = "Spider-b" }
-- )
vim.api.nvim_create_autocmd('FileType', {
	pattern = "dts",
	callback = function(ev)
		vim.lsp.start({
			name = 'dts-lsp',
			cmd = { 'dts-lsp' },
			root_dir = vim.fs.dirname(vim.fs.find({ '.git' }, { upward = true })[1]),
		})
	end
})

vim.keymap.set("n", "c]", function()
	ts_context.go_to_context(vim.v.count1)
end, { silent = true })

require('ruscmd').setup {
}

vim.api.nvim_set_hl(0, 'LspInlayHint', {
	fg = '#7f7f7f', -- Light gray foreground (adjust to your theme)
	bg = 'NONE', -- Transparent background
})


require('gitblame').setup()
require('plantuml').setup()
require('crates').setup {
	lsp = {
		enabled = true,
		on_attach = function(client, bufnr)
			-- the same on_attach function as for your other language servers
			-- can be ommited if you're using the `LspAttach` autocmd
		end,
		actions = true,
		completion = true,
		hover = true,
	},
}


vim.keymap.set('i', '<C-J>', 'copilot#Accept("\\<CR>")', {
	expr = true,
	replace_keycodes = false
})

vim.g.copilot_no_tab_map = true
vim.g.copilot_filetypes = {
	["*"] = true,
	-- ["markdown"] = false,
}

vim.o.sessionoptions = "blank,buffers,curdir,help,tabpages,winsize,winpos,localoptions,terminal"
vim.g.db_ui_execute_on_save = 0
vim.g.db_ui_show_database_icon = 1
vim.g.db_ui_use_nerd_fonts = 1

local left_menu_mode = 'tree'
local is_left_menu_open = false

local code_action = function()
	if left_menu_mode == 'tree' then
		vim.lsp.buf.code_action()
	elseif left_menu_mode == 'db' then
		vim.api.nvim_input('\\<Plug>(DBUI_ExecuteQuery)')
	end
end

vim.keymap.set("n", "<M-CR>", code_action, opts)
vim.keymap.set("v", "<M-CR>", code_action, opts)


local toggle_db_view = function()
	local api = require("nvim-tree.api")

	if left_menu_mode == 'tree' then
		if api.tree.is_visible() then
			api.tree.close()
		end

		left_menu_mode = 'db'
		-- by default dbui will open left menu
		vim.cmd("DBUI")

		if not is_left_menu_open then
			vim.cmd("DBUIToggle")
		end
	elseif left_menu_mode == 'db' then
		vim.cmd("DBUIClose")
		if is_left_menu_open then
			api.tree.open()
		end

		left_menu_mode = 'tree'
	end
end

local toggle_left_menu = function()
	if left_menu_mode == 'tree' then
		local api = require("nvim-tree.api")
		if api.tree.is_visible() then
			api.tree.close()
		else
			api.tree.open()
		end
	elseif left_menu_mode == 'db' then
		vim.cmd("DBUIToggle")
	end
end

local function focus_left_menu()
	if left_menu_mode == 'tree' then
		local api = require("nvim-tree.api")
		is_left_menu_open = true
		if api.tree.is_visible() then
			api.tree.focus()
		else
			api.tree.open()
			api.tree.focus()
		end
	end
end

-- vim.keymap.set("n", "<F4>", [[<cmd>DBUI<cr>]])
vim.keymap.set("n", "<F4>", toggle_db_view, { desc = "Open DBUI" })

vim.keymap.set('n', '<M-1>', toggle_left_menu, { noremap = true, silent = true })
vim.keymap.set('n', '<M-F1>', focus_left_menu, { noremap = true, silent = true })

local function on_session_save()
	require('nvim-tree.api').tree.close()

	is_left_menu_open = false
end

local function on_session_restore()
	local api = require "nvim-tree.api"
	-- Update NvimTree's root to the current working directory
	api.tree.change_root(vim.fn.getcwd())
	-- Optionally, find and focus the current buffer's file
	api.tree.find_file({ open = true, focus = true })

	is_left_menu_open = true
end

require('auto-session').setup({
	log_level = 'warn',
	auto_session_suppress_dirs = { '~/', '~/Downloads', '~/Documents', '/' },
	-- post_restore_cmds = { 'NvimTreeOpen' }, -- Open NvimTree after restoring session
	-- pre_save_cmds = { 'NvimTreeClose' }, -- Close NvimTree before saving session
	post_restore_cmds = {
		function()
			on_session_restore()
		end,
	},
	pre_save_cmds = {
		-- Close NvimTree before saving to avoid session conflicts
		function()
			on_session_save()
		end,
	},
	cwd_change_handling = true,

	session_lens = {
		load_on_setup = true, -- Initialize on startup (requires Telescope)
		picker_opts = nil,
		-- Table passed to Telescope / Snacks to configure the picker. See below for more information
		-- mappings = {
		--   -- Mode can be a string or a table, e.g. {"i", "n"} for both insert and normal mode
		--   delete_session = { "i", "<C-D>" },
		--   alternate_session = { "i", "<C-S>" },
		--   copy_session = { "i", "<C-Y>" },
		-- },

		session_control = {
			control_dir = vim.fn.stdpath "data" .. "/auto_session/", -- Auto session control dir, for control files, like alternating between two sessions with session-lens
			control_filename = "session_control.json", -- File name of the session control file
		},
	},
})

vim.keymap.set('n', 'cvx', ':Telescope session-lens<CR>', {})


-- Function for search and replace with Telescope
local function telescope_search_replace()
	-- Prompt for the word to find
	local find = vim.fn.input("Find: ")
	if find == "" then return end

	-- Prompt for the replacement word
	local replace = vim.fn.input("Replace with: ")
	if replace == "" then return end

	-- Escape special characters for the substitute command
	local esc_find = vim.fn.escape(find, '/')
	local esc_replace = vim.fn.escape(replace, '/')

	-- Load Telescope modules
	local actions = require("telescope.actions")
	local action_state = require("telescope.actions.state")

	-- Open Telescope live_grep with prefilled search and custom mapping
	require("telescope.builtin").live_grep({
		default_text = find,
		attach_mappings = function(prompt_bufnr, map)
			map("i", "<M-CR>", function()
				local picker = action_state.get_current_picker(prompt_bufnr)
				local selections = picker:get_multi_selection()

				-- If no selections, use all entries; otherwise, use selected entries
				if #selections == 0 then
					actions.send_to_qflist(prompt_bufnr)
				else
					-- Populate quickfix with only selected entries
					local qf_entries = {}
					for _, entry in ipairs(selections) do
						table.insert(qf_entries, {
							filename = entry.filename,
							lnum = entry.lnum,
							col = entry.col,
							text = entry.text,
						})
					end
					vim.fn.setqflist(qf_entries)
				end

				-- Close Telescope
				actions.close(prompt_bufnr)

				-- Execute the replacement across quickfix entries
				local command = string.format("cfdo %%s/%s/%s/g | update", esc_find, esc_replace)
				vim.cmd(command)
			end)
			-- Return true to preserve default Telescope mappings
			return true
		end,
	})
end

-- Set the keybinding for 'cvr' in normal mode
vim.keymap.set("n", "cvr", telescope_search_replace, { desc = "Search and replace across project" })

require("bigfile").setup {
	filesize = 1, -- size of the file in MiB, the plugin round file sizes to the closest MiB
	pattern = { "*" }, -- autocmd pattern or function see <### Overriding the detection of big files>
	features = { -- features to disable
		"indent_blankline",
		"illuminate",
		"lsp",
		"treesitter",
		"syntax",
		"matchparen",
		"vimopts",
		"filetype",
	},
}

require('snacks').setup {
	defaults = {
		border = 'rounded',
		max_width = 80,
		max_height = 20,
		timeout = 5000,
	},
	picker = {}, terminal = {}, input = {},
	bigfile = {
		size = 0.8 * 1024 * 1024,
		line_length = 1000
	},
	image = {},
}

require('lualine').setup {
	sections = {
		lualine_a = { 'mode' },
		lualine_b = { 'branch', 'diff', 'diagnostics' },
		lualine_c = { { 'filename', path = 1 } },
		lualine_x = {
			{ require("session_todo").get_statusline, color = { fg = "#50fa7b" } }
		},
		lualine_y = { 'encoding', 'fileformat', 'filetype', 'progress' },
		lualine_z = { 'location' }

	},

	inactive_sections = {
		lualine_a = {},
		lualine_b = {},
		lualine_c = { { 'filename', path = 1 } },
		lualine_x = { 'location' },
		lualine_y = {},
		lualine_z = {}

	},

	tabline = {},

	extensions = {}

}

vim.g.opencode_opts = {
	-- Your configuration, if any — see `lua/opencode/config.lua`, or "goto definition" on the type or field.
}

-- Required for `opts.events.reload`.
vim.o.autoread = true

-- Recommended/example keymaps.
vim.keymap.set({ "n", "x" }, "<leader>a", function() require("opencode").ask("@this: ", { submit = true }) end,
	{ desc = "Ask opencode…" })
vim.keymap.set({ "n", "x" }, "<leader>s", function() require("opencode").select() end,
	{ desc = "Execute opencode action…" })
vim.keymap.set("n", "<leader>l", function() return require("opencode").operator("@this ") .. "_" end,
	{ desc = "Add line to opencode", expr = true })
-- vim.keymap.set({"n","t"}, "<M-s>", function() return require("opencode").command("session.list") end, { desc = "Show OpenCode sessions", expr = true })
vim.keymap.set({ "n", "t" }, "cva", function() require("opencode").toggle() end, { desc = "Toggle opencode" })

local last_non_terminal_win = nil

vim.keymap.set({ "n", "t" }, "<M-F12>", function()
	local current_win = vim.api.nvim_get_current_win()
	local current_buf = vim.api.nvim_win_get_buf(current_win)
	local current_buftype = vim.api.nvim_buf_get_option(current_buf, "buftype")

	-- If currently in terminal, go back to previous window
	if current_buftype == "terminal" then
		if last_non_terminal_win and vim.api.nvim_win_is_valid(last_non_terminal_win) then
			vim.api.nvim_set_current_win(last_non_terminal_win)
		else
			-- If no valid previous window, find any non-terminal window
			local windows = vim.api.nvim_list_wins()
			for _, win in ipairs(windows) do
				if win ~= current_win then
					local buf = vim.api.nvim_win_get_buf(win)
					local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
					if buftype ~= "terminal" then
						vim.api.nvim_set_current_win(win)
						return
					end
				end
			end
		end
	else
		-- Currently not in terminal, save position and switch to terminal
		last_non_terminal_win = current_win

		-- Find first terminal window
		local windows = vim.api.nvim_list_wins()
		for _, win in ipairs(windows) do
			local buf = vim.api.nvim_win_get_buf(win)
			local buftype = vim.api.nvim_buf_get_option(buf, "buftype")

			if buftype == "terminal" then
				vim.api.nvim_set_current_win(win)
				-- Enter insert mode in terminal
				vim.cmd("startinsert")
				return
			end
		end

		-- No terminal found
		print("No terminal window found")
	end
end, { noremap = true, silent = true })
require('gitsigns').setup {
	on_attach = function(bufnr)
		local gitsigns = require('gitsigns')

		local function map(mode, l, r, opts)
			opts = opts or {}
			opts.buffer = bufnr
			vim.keymap.set(mode, l, r, opts)
		end

		-- Navigation
		map('n', ']c', function()
			if vim.wo.diff then
				vim.cmd.normal({ ']c', bang = true })
			else
				gitsigns.nav_hunk('next')
			end
		end)

		map('n', '[c', function()
			if vim.wo.diff then
				vim.cmd.normal({ '[c', bang = true })
			else
				gitsigns.nav_hunk('prev')
			end
		end)

		-- Actions
		map('n', '<leader>hs', gitsigns.stage_hunk)
		map('n', '<leader>hr', gitsigns.reset_hunk)

		map('v', '<leader>hs', function()
			gitsigns.stage_hunk({ vim.fn.line('.'), vim.fn.line('v') })
		end)

		map('v', '<leader>hr', function()
			gitsigns.reset_hunk({ vim.fn.line('.'), vim.fn.line('v') })
		end)

		map('n', '<leader>hS', gitsigns.stage_buffer)
		map('n', '<leader>hR', gitsigns.reset_buffer)
		map('n', '<leader>hp', gitsigns.preview_hunk)
		map('n', '<leader>hi', gitsigns.preview_hunk_inline)

		map('n', '<leader>hb', function()
			gitsigns.blame_line({ full = true })
		end)

		map('n', '<leader>hd', gitsigns.diffthis)

		map('n', '<leader>hD', function()
			gitsigns.diffthis('~')
		end)

		map('n', '<leader>hQ', function() gitsigns.setqflist('all') end)
		map('n', '<leader>hq', gitsigns.setqflist)

		-- Toggles
		map('n', '<leader>tb', gitsigns.toggle_current_line_blame)
		map('n', '<leader>tw', gitsigns.toggle_word_diff)

		-- Text object
		map({ 'o', 'x' }, 'ih', gitsigns.select_hunk)
	end
}

require("session_todo").setup({
	work_duration = 25 * 60, -- 25 minutes
	short_break = 5 * 60, -- 5 minutes
	long_break = 15 * 60, -- 15 minutes
})

require("claude-code").setup()
-- require("dev-tools").setup({
--   bdd = {
--     enabled = true,
--     display_mode = "float", 
--   }
-- })

vim.keymap.set({ 'n', 't' }, '<F5>', function()
	vim.fn.system('tmux resize-pane -D 1 && tmux resize-pane -U 1')
end, { desc = "Tmux dummy resize" })





-- vim.keymap.set({ "n", "x" }, "go",  function() return require("opencode").operator("@this ") end,        { desc = "Add range to opencode", expr = true })
-- vim.keymap.set("n",          "goo", function() return require("opencode").operator("@this ") .. "_" end, { desc = "Add line to opencode", expr = true })
--
-- vim.keymap.set("n", "<S-C-u>", function() require("opencode").command("session.half.page.up") end,   { desc = "Scroll opencode up" })
-- vim.keymap.set("n", "<S-C-d>", function() require("opencode").command("session.half.page.down") end, { desc = "Scroll opencode down" })
--
-- -- You may want these if you stick with the opinionated "<C-a>" and "<C-x>" above — otherwise consider "<leader>o…".
-- vim.keymap.set("n", "+", "<C-a>", { desc = "Increment under cursor", noremap = true })
-- vim.keymap.set("n", "-", "<C-x>", { desc = "Decrement under cursor", noremap = true })

-- Treesitter: install small curated list of parsers on startup
-- (new nvim-treesitter API - old setup block was removed)
local ts_parsers = {
  "bash", "c", "cpp", "go", "javascript", "json", "lua",
  "markdown", "python", "rust", "sql", "toml", "typescript", "vim", "yaml"
}
require('nvim-treesitter').install(ts_parsers)

-- Enable treesitter highlighting for the curated languages
vim.api.nvim_create_autocmd('FileType', {
  pattern = ts_parsers,
  callback = function(ev)
    vim.treesitter.start(ev.buf)
  end,
})
