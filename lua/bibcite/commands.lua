local bibtex = require 'bibcite.bibtex'
local pdfutils = require 'bibcite.pdfutils'
local telescope_picker = require 'bibcite.telescope_picker'

local M = {}

-- Opens a popup window with information of the entry
-- you are currently hovering over.
local function show_citation_popup()
  -- This already ignores extra symbols around it
  local word = vim.fn.expand '<cword>'
  local match = nil

  -- Find the entry with matching key
  for _, entry in ipairs(bibtex.entries or {}) do
    if entry.key == word then
      match = entry
      break
    end
  end

  if not match then
    vim.notify('No BibTeX entry found for key: ' .. word, vim.log.levels.INFO)
    return
  end

  local lines = {
    'Author: ' .. (match.author or 'N/A'),
    'Title:  ' .. (match.title or 'N/A'),
    'Year:   ' .. (match.year or 'N/A'),
  }

  local width = 0
  for _, line in ipairs(lines) do
    width = math.max(width, #line)
  end

  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

  local win = vim.api.nvim_open_win(buf, false, {
    relative = 'cursor',
    row = 1,
    col = 0,
    width = width + 2,
    height = #lines,
    style = 'minimal',
    border = 'rounded',
  })

  -- Close on CursorMoved or ModeChanged
  local close_events = { 'CursorMoved', 'ModeChanged' }
  for _, evt in ipairs(close_events) do
    vim.api.nvim_create_autocmd(evt, {
      buffer = 0,
      once = true,
      callback = function()
        if vim.api.nvim_win_is_valid(win) then
          vim.api.nvim_win_close(win, true)
        end
      end,
    })
  end

  -- Close on keypress
  local key_close = vim.on_key(function()
    if vim.api.nvim_win_is_valid(win) then
      vim.api.nvim_win_close(win, true)
    end
    vim.on_key(nil, vim.api.nvim_create_namespace 'bibcite_popup')
  end, vim.api.nvim_create_namespace 'bibcite_popup')
end

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
  vim.api.nvim_create_user_command('CitePeek', show_citation_popup, {})

  vim.api.nvim_create_user_command('CiteOpen', open_pdf_under_cursor, {})
end

return M
