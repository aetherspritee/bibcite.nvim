-- Multiple actions require you to pick an entry
-- This file contains a reusable picker for bib entries.
-- Telescope documentation on how to set up pickers:
-- https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md

local bibtex = require 'bibcite.bibtex'

local pickers = require 'telescope.pickers'
local finders = require 'telescope.finders'
local conf = require('telescope.config').values
local actions = require 'telescope.actions'
local action_state = require 'telescope.actions.state'

local M = {}

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

  local telescope_opts = {}

  pickers
    .new(telescope_opts, {
      prompt_title = prompt_title,
      finder = finders.new_table {
        -- Telescope does not allow us to re-use the hashmap.
        -- Fortunately we have all the fields stored on the actual value of
        -- The key-value pair. So we can pass bibtex.entries
        results = dictionary_values_only(bibtex.entries),
        entry_maker = function(entry)
          local search_text = table.concat({
            entry.key or '',
            entry.author or '',
            entry.title or '',
            entry.year or '',
            entry.journal or '',
          }, ' ')
          return {
            -- So we have access to the original entry
            value = entry,
            -- What is displayed in the picker window
            display = entry.key,
            -- What is actually searched for
            ordinal = search_text,
            -- -- These are needed to prevent Telescope from trying to "jump" the cursor
            -- filename = vim.api.nvim_buf_get_name(0), -- or just some placeholder file
            -- lnum = 1,
          }
        end,
      },
      sorter = conf.generic_sorter(telescope_opts),

      -- Call the provided functor when you select it.
      -- This implementation is almost verbatim that of the telescope API example for attach_mappings.
      attach_mappings = function(prompt_bufnr, map)
        actions.select_default:replace(function()
          actions.close(prompt_bufnr)
          local selection = action_state.get_selected_entry()
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
