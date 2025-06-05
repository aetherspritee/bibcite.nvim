-- This file is an entry point, responsible for setup
local M = {}

function M.setup(opts)
  require('bibcite.config').setup(opts)
  local bib_loader = require 'bibcite.bibtex'
  -- TODO: Keep track of all the files that have been opened. That way, a 'Reload' command can re-load all the previously opened files
  bib_loader.load_bib_from_config()
  bib_loader.load_all_bibs_in_pwd()
  require('bibcite.commands').setup()
end

-- TODO: Highlight everything in the current buffer that could be a bibentry.
-- TODO: Add GIFs to the README.
-- TODO: Add autocompletion source for citekeys. Ideally, with a popup above at the same time showing a little excerpt.
-- TODO: Add option to read notes files as well when discovering files.
-- Make this an option because it'll slow down the startup even more.
-- Maybe an extra function that also notifies how many notes have been found.

return M
