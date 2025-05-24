local bibtex = require 'bibcite.bibtex'
local open_external_file = require 'bibcite.open_external_file'
local telescope_picker = require 'bibcite.telescope_picker'
local popup = require 'bibcite.popup'

local M = {}

-- Register Neovim commands
function M.setup()
  -- Create :CiteInsert command to insert citation key into buffer
  vim.api.nvim_create_user_command('CiteInsert', function()
    telescope_picker.telescope_entry_picker('Insert Citation', function(entry)
      if entry then
        vim.api.nvim_put({ entry.key }, '', true, true)
      end
    end)
  end, {})

  -- Create :CiteDebug command to print loaded BibTeX entries
  vim.api.nvim_create_user_command('CiteDebug', function()
    bibtex.debug_print_entries()
  end, {})

  -- :CitePeek to show citation popup
  vim.api.nvim_create_user_command('CitePeek', popup.show_citation_popup, {})

  vim.api.nvim_create_user_command('CiteOpen', open_external_file.open_external_file_of_refentry_under_cursor, {})
end

return M
