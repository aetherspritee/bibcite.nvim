-- This file is an entry point, responsible for setup
local M = {}

function M.setup(opts)
  require('bibcite.config').setup(opts)
  require('bibcite.bibtex').load_bib()
  require('bibcite.commands').setup()
end

return M
