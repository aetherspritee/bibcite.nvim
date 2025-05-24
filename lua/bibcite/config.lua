-- Handling plugin user configuration

-- These are all the options that are exposed.
local M = {
  options = {
    bibtex_path = nil,
    pdf_dir = nil, -- base path for :files/
  },
}

-- Merge user-provided options with defaults. User options take
-- precedence.
function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', M.options, opts or {})
end

return M
