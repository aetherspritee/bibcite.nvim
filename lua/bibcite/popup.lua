-- Opens a popup window with information of the entry
-- you are currently hovering over.

local bibtex = require 'bibcite.bibtex'

local M = {}

function M.show_citation_popup()
  -- This already ignores extra symbols around it
  -- [Smith2020]
  -- Smith2020,
  -- :Smith:2020
  local word = vim.fn.expand '<cword>'
  local match = nil

  -- Find the entry with matching key
  for _, entry in pairs(bibtex.entries or {}) do
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

  -- TODO: Add show first N lines of the notes field.
  -- TODO: Show whether or not there is a PDF/external file attached that can be opened.

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

return M
