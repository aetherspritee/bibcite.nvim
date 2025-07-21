-- Multiple actions require you to pick an entry
-- This file contains a reusable picker for bib entries.
-- Telescope documentation on how to set up pickers:
-- https://github.com/nvim-telescope/telescope.nvim/blob/master/developers.md

local bibtex = require 'bibcite.bibtex'

local M = {}

-- Telescope does not like key-value pair. So, small function to convert it to just the data, not with the key :)
local function dictionary_values_only(entries_dict)
  local result = {}
  for _, entry in pairs(entries_dict) do
    table.insert(result, entry)
  end
  return result
end

local function remove_newlines(value)
  -- Ensuring it is a string shouldn't be necessary, but here just in case.
  local str = tostring(value or '')
  -- If you have a newline in there, telescope will throw a "index outside of buffer" error.
  return str:gsub('[\r\n]', ' ')
end

-- Make an entry as a table.
-- Set up in a way similar to https://github.com/nvim-telescope/telescope.nvim/blob/b4da76be54691e854d3e0e02c36b0245f945c2c7/lua/telescope/make_entry.lua#L4
local function make_entry(entry)
  local entry_display = require 'telescope.pickers.entry_display'

  local displayer = entry_display.create {
    separator = ' │ ',
    items = {
      { width = 20 }, -- key
      { width = 25 }, -- author
      { remaining = true }, -- title
    },
  }

  -- Normalize only required fields
  local key = entry.key or ''
  local author = entry.author or ''
  local title = entry.title or ''

  local function make_display()
    -- print(key .. title)
    return displayer {
      { remove_newlines(key), nil },
      -- TODO: Do santization in loading the actual bib instead?
      { remove_newlines(author), nil },
      { remove_newlines(title), nil },
    }
  end

  return {
    value = entry,
    ordinal = table.concat({ key, author, title }, ' '),
    display = make_display,
    key = entry.key,
    author = entry.author,
    title = entry.title,
  }
end

-- Reusable Telescope picker function to select a BibTeX entry
-- Accepts a prompt_title and a callback to call with the selected entry
function M.telescope_entry_picker(prompt_title, on_select)
  -- Return early if telescope is not installed.
  -- Might implement something in the config at some point that allows you to use other pickers too.
  local has_telescope, _ = pcall(require, 'telescope')
  if not has_telescope then
    vim.notify('[bibcite] Telescope is not available', vim.log.levels.ERROR)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  local telescope_opts = {}

  pickers
    .new(telescope_opts, {
      prompt_title = prompt_title,
      finder = finders.new_table {
        -- Telescope does not allow us to re-use the hashmap.
        -- Fortunately we have all the fields stored on the actual value of
        -- The key-value pair. So we can pass bibtex.entries
        results = dictionary_values_only(bibtex.entries),
        entry_maker = make_entry,
      },
      sorter = conf.generic_sorter(telescope_opts),

      -- Call the provided functor when you select it.
      -- This implementation is almost verbatim that of the telescope API example for attach_mappings.
      attach_mappings = function(prompt_bufnr, _)
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
