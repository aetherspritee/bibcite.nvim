-- Multiple actions require you to pick an entry
-- This file contains a reusable picker for bib entries.
-- Telescope documentation on how to set up pickers:
-- https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md

local bibtex = require 'bibcite.bibtex'

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

-- Telescope does not like key-value pair. So, small function to convert it to just the data, not with the key :)
local function dictionary_values_only(entries_dict)
  local result = {}
  for _, entry in pairs(entries_dict) do
    table.insert(result, entry)
  end
  return result
end

-- Reusable Telescope picker function to select a BibTeX entry
-- Accepts a prompt_title and a callback to call with the selected entry
function M.telescope_entry_picker(prompt_title, on_select)
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
        results = dictionary_values_only(bibtex.entries),
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
            -- These are needed to prevent Telescope from trying to "jump" the cursor
            filename = vim.api.nvim_buf_get_name(0), -- or just some placeholder file
            lnum = 1,
          }
        end,
      },
      sorter = conf.generic_sorter {},

      -- previewer = previewers.new_buffer_previewer {
      --   define_preview = function(self, entry, _)
      --     local e = entry.value
      --     local lines = {}
      --     -- With a little margin to prevent bleed.
      --     local text_width = vim.api.nvim_win_get_width(self.state.winid) - 3
      --
      --     table.insert(lines, string.format('Key: %s', e.key or ''))
      --     table.insert(lines, '')
      --
      --     table.insert(lines, 'Author(s):')
      --     vim.list_extend(lines, wrap_text(e.author or 'N/A', text_width))
      --     table.insert(lines, '')
      --
      --     table.insert(lines, string.format('Year: %s', e.year or ''))
      --     table.insert(lines, '')
      --
      --     table.insert(lines, 'Title:')
      --     vim.list_extend(lines, wrap_text(e.title or 'N/A', text_width))
      --     table.insert(lines, '')
      --
      --     if e.doi then
      --       table.insert(lines, 'DOI:')
      --       table.insert(lines, e.doi)
      --       table.insert(lines, '')
      --     end
      --
      --     if e.file then
      --       table.insert(lines, '📎 Attached File')
      --     else
      --       table.insert(lines, '— No file attached')
      --     end
      --     table.insert(lines, '')
      --
      --     table.insert(lines, 'Abstract:')
      --     if e.abstract then
      --       vim.list_extend(lines, wrap_text(e.abstract, text_width))
      --     else
      --       table.insert(lines, 'N/A')
      --     end
      --
      --     -- TODO: Add first n lines of the notes you wrote.
      --     vim.api.nvim_buf_set_lines(self.state.bufnr, 0, -1, false, lines)
      --   end,
      -- },

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

return M
