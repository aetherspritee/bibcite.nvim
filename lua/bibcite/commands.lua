local bibtex = require 'bibcite.bibtex'
local pdfutils = require 'bibcite.pdfutils'

local M = {}

-- Format how each BibTeX entry is displayed in Telescope
local function format_display(entry)
  local parts = {}
  if entry.key then
    table.insert(parts, string.format('[%s]', entry.key))
  end
  if entry.author then
    table.insert(parts, entry.author)
  end
  if entry.year then
    table.insert(parts, string.format('(%s)', entry.year))
  end
  if entry.title then
    table.insert(parts, ': ' .. entry.title)
  end
  return table.concat(parts, ' ')
end

-- Helper function because vim does not auto-wrap text.
local function wrap_text(text, width)
  local lines = {}
  for line in text:gmatch '[^\n]+' do
    local current = ''
    for word in line:gmatch '%S+' do
      if vim.fn.strdisplaywidth(current .. ' ' .. word) > width then
        table.insert(lines, current)
        current = word
      else
        current = current == '' and word or (current .. ' ' .. word)
      end
    end
    if current ~= '' then
      table.insert(lines, current)
    end
  end
  return lines
end

-- Reusable Telescope picker function to select a BibTeX entry
-- Accepts a prompt_title and a callback to call with the selected entry
function M.pick_entry(prompt_title, on_select)
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    vim.notify('[bibcite] Telescope is not available', vim.log.levels.ERROR)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'
  local previewers = require 'telescope.previewers'
  local entry_display = require 'telescope.pickers.entry_display'

  pickers
    .new({}, {
      prompt_title = prompt_title,
      finder = finders.new_table {
        results = bibtex.entries,
        entry_maker = function(entry)
          local display = format_display(entry)
          local search_text = table.concat({
            entry.key or '',
            entry.author or '',
            entry.title or '',
            entry.year or '',
            entry.journal or '',
          }, ' ')
          return {
            value = entry,
            display = display,
            ordinal = search_text,
          }
        end,
      },
      sorter = conf.generic_sorter {},

      previewer = previewers.new_buffer_previewer {
        define_preview = function(self, entry, _)
          local e = entry.value
          local lines = {}
          -- With a little margin to prevent bleed.
          local text_width = vim.api.nvim_win_get_width(self.state.winid) - 3

          table.insert(lines, string.format('Key: %s', e.key or ''))
          table.insert(lines, '')

          table.insert(lines, 'Author(s):')
          vim.list_extend(lines, wrap_text(e.author or 'N/A', text_width))
          table.insert(lines, '')

          table.insert(lines, string.format('Year: %s', e.year or ''))
          table.insert(lines, '')

          table.insert(lines, 'Title:')
          vim.list_extend(lines, wrap_text(e.title or 'N/A', text_width))
          table.insert(lines, '')

          if e.doi then
            table.insert(lines, 'DOI:')
            table.insert(lines, e.doi)
            table.insert(lines, '')
          end

          if e.file then
            table.insert(lines, '📎 Attached File')
          else
            table.insert(lines, '— No file attached')
          end
          table.insert(lines, '')

          table.insert(lines, 'Abstract:')
          if e.abstract then
            vim.list_extend(lines, wrap_text(e.abstract, text_width))
          else
            table.insert(lines, 'N/A')
          end

          vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
        end,
      },

      attach_mappings = function(_, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(_)
          if selection and on_select then
            on_select(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Opens a popup window with information of the entry
-- you are currently hovering over.
local function show_citation_popup()
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
    M.pick_entry('Insert Citation', function(entry)
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
