-- This file contains a reusable picker for bib entries, using the Snacks library.

local bibtex = require 'bibcite.bibtex'

local M = {}

-- Reusable Snacks picker function to select a BibTeX entry
-- Accepts a prompt_title and a callback to call with the selected entry
function M.snacks_entry_picker(prompt_title, on_select, attach_mappings_opts)
  local has_snacks, snacks = pcall(require, "snacks")

  if not has_snacks then
    vim.notify('[bibcite] Snacks is not available', vim.log.levels.ERROR)
    return
  end

  local entries = {}
  for _, entry in pairs(bibtex.entries) do
    table.insert(entries, entry)
  end

  local function format_entry(entry)
    local key = entry.key or ''
    local author = entry.author or ''
    local title = entry.title or ''
    local year = entry.year or ''
    return {
      { string.format('%-18s', key), 'SnacksPickerName' },
      { string.format('%-25s', author), 'SnacksPickerPath' },
      { string.format('%-4s', year), 'SnacksPickerName' },
      { title, 'SnacksPickerPath' },
    }
  end

  local picker = snacks.picker({
    title = prompt_title,
    items = entries,
    format = format_entry,
    on_select = function(item)
      if item and on_select then
        on_select(item)
      end
    end,
  })

  if attach_mappings_opts then
    for key, func in pairs(attach_mappings_opts) do
      picker:map("n", key, function(item)
        if item then
          func(item)
        end
      end)
    end
  end

  picker:show()
end

return M