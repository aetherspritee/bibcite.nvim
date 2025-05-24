local bibtex = require 'bibcite.bibtex'
local pdfutils = require 'bibcite.pdfutils'
local telescope_picker = require 'bibcite.telescope_picker'
local popup = require 'bibcite.popup'

local M = {}

-- Checks if the entry under the cursor has an associated file (PDF), and opens it if it does.
local function open_pdf_under_cursor()
  local key = vim.fn.expand '<cword>'
  for _, entry in ipairs(bibtex.entries or {}) do
    if entry.key == key then
      local path = pdfutils.resolve_pdf_path(entry.file)
      if path and vim.fn.filereadable(path) == 1 then
        pdfutils.open_file(path)
      else
        vim.notify('[bibcite] PDF not found: ' .. (path or 'nil'), vim.log.levels.WARN)
      end
      return
    end
  end
  vim.notify('[bibcite] No BibTeX entry for key: ' .. key, vim.log.levels.INFO)
end

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

  vim.api.nvim_create_user_command('CiteOpen', open_pdf_under_cursor, {})
end

return M
