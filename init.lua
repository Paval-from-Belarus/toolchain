vim.opt.clipboard:append('unnamedplus')
vim.opt.number = true
vim.opt.termguicolors = true
vim.opt.ruler = true
vim.opt.wrap = false
vim.opt.showmode = false

require('config.plugins')
require('config.setup')

vim.cmd('highlight rustLifetime guifg=#20999d')

vim.api.nvim_create_autocmd('FileType', {
  pattern = { 'sql', 'mysql', 'plsql' },
  callback = function()
    vim.schedule(function()
      local ok, cmp = pcall(require, 'cmp')
      if ok then
        cmp.setup.buffer({ sources = { { name = 'vim-dadbod-completion' } } })
      end
    end)
  end,
})
