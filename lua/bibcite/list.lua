
-- This file is responsible for the `CiteList` command.
-- It will display all entries in a Telescope picker, with keybindings to open the PDF, notes, or the BibTeX entry.

local snacks_picker = require 'bibcite.snacks_picker'
local open_external_file = require 'bibcite.open_external_file'
local bibtex = require 'bibcite.bibtex'

local M = {}

function M.list_all_entries()
  snacks_picker.snacks_entry_picker('All Entries', function(entry)
    -- Default action: do nothing
  end, {
    ['<C-o>'] = function(entry)
      open_external_file.open_external_file_of_entry(entry)
    end,
    ['<C-n>'] = function(entry)
      open_external_file.open_note_of_entry(entry)
    end,
    ['<C-s>'] = function(entry)
      bibtex.open_bibtex_entry(entry)
    end,
  })
end

return M
