local M = {}

M._config = {
  keymap = "<leader>tt",
}

function M.setup(opts)
  opts = opts or {}
  M._config = vim.tbl_deep_extend("force", M._config, opts)

  if M._config.keymap then
    vim.keymap.set("n", M._config.keymap, function()
      require("rust-test-panel").open()
    end, { desc = "Rust test panel" })
  end

  vim.api.nvim_create_user_command("RustTests", function()
    M.open()
  end, { desc = "Open Rust test panel" })
end

function M.open()
  local bufnr = vim.api.nvim_get_current_buf()
  if vim.bo[bufnr].filetype ~= "rust" then
    vim.notify("rust-test-panel: not a Rust buffer", vim.log.levels.WARN)
    return
  end

  local entries = require("rust-test-panel.discovery").collect(bufnr)
  require("rust-test-panel.ui").open(entries)
end

return M
