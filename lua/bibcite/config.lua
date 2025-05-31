-- Handling plugin user configuration

-- These are all the options that are exposed.
local M = {
  options = {
    -- Path for the default .bib file to open
    bibtex_path = nil,
    -- Directory where the current .bib file expects to be able to find external pdf files.
    pdf_dir = nil,
    -- Directory where you store your notes. Notes are expected to have the name of the citekey.
    notes_dir = nil,
  },
}

-- Merge user-provided options with defaults. User options take
-- precedence.
function M.setup(opts)
  M.options = vim.tbl_deep_extend('force', M.options, opts or {})
end

return M
