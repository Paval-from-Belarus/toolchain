local M = {}

--- Get the git root directory for the current buffer or cwd
--- @return string|nil
function M.get_git_root()
  local git_root = vim.fn.systemlist('git -C ' .. vim.fn.shellescape(vim.fn.getcwd()) .. ' rev-parse --show-toplevel 2>/dev/null')[1]
  if vim.v.shell_error ~= 0 or not git_root or git_root == '' then
    return nil
  end
  return git_root
end

return M
