
-- This file contains a reusable picker for bib entries, using the Snacks library.

local bibtex = require 'bibcite.bibtex'
local snacks = require 'snacks'

local M = {}

-- Reusable Snacks picker function to select a BibTeX entry
-- Accepts a prompt_title and a callback to call with the selected entry
function M.snacks_entry_picker(prompt_title, on_select, attach_mappings_opts)
  local entries = {}
  for _, entry in pairs(bibtex.entries) do
    table.insert(entries, entry)
  end

  local function format_entry(entry)
    local key = entry.key or ''
    local author = entry.author or ''
    local title = entry.title or ''
    local year = entry.year or ''
    return string.format('%-18s %-25s %-4s %s', key, author, year, title)
  end

  local picker = snacks.create_picker({
    title = prompt_title,
    items = entries,
    item_formatter = format_entry,
    on_select = function(entry)
      if entry and on_select then
        on_select(entry)
      end
    end,
  })

  if attach_mappings_opts then
    for key, func in pairs(attach_mappings_opts) do
      picker:register_action(key, function(entry)
        if entry then
          func(entry)
        end
      end)
    end
  end

  picker:open()
end

return M
