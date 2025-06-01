-- This file is an entry point, responsible for setup
local M = {}

function M.setup(opts)
  require('bibcite.config').setup(opts)
  local bib_loader = require 'bibcite.bibtex'
  bib_loader.load_bib_from_config()
  bib_loader.load_all_bibs_in_pwd()
  require('bibcite.commands').setup()
end

return M
