-- Handling plugin user configuration

local M = {
  options = {
    bibtex_path = nil,
  },
}

-- Merge user-provided options with defaults
function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', M.options, opts or {})
end

return M
