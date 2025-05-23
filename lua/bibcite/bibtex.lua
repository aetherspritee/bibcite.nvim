-- Functionality for loading and parsing a .bib file

local config = require 'bibcite.config'
local M = {}

local function parse_bibtex(file)
  local entries = {}
  local current_entry = nil
  local brace_level = 0
  local inside_entry = false

  for line in io.lines(file) do
    if not inside_entry and line:match '^@' then
      current_entry = line
      brace_level = select(2, line:gsub('{', '')) - select(2, line:gsub('}', ''))
      inside_entry = true
    elseif inside_entry then
      current_entry = current_entry .. '\n' .. line
      brace_level = brace_level + select(2, line:gsub('{', '')) - select(2, line:gsub('}', ''))
      if brace_level <= 0 then
        local entry = {}
        local entry_type, key = current_entry:match '^@(%w+)%s*{%s*([^,%s]+)'
        if entry_type and key then
          entry.key = key
          entry.type = entry_type

          for field, value in current_entry:gmatch '([%w_]+)%s*=%s*{(.-)}%s*,?' do
            entry[field:lower()] = value
          end
          for field, value in current_entry:gmatch '([%w_]+)%s*=%s*"(.-)"%s*,?' do
            entry[field:lower()] = value
          end

          table.insert(entries, entry)
        end
        current_entry = nil
        inside_entry = false
      end
    end
  end

  return entries
end
function M.load_bib()
  local path = config.options.bibtex_path
  if not path or path == '' then
    vim.notify('[bibcite] No BibTeX file path specified.', vim.log.levels.ERROR)
    return
  end

  local ok, entries = pcall(parse_bibtex, path)
  if not ok then
    vim.notify('[bibcite] Failed to load .bib file: ' .. entries, vim.log.levels.ERROR)
    return
  end

  M.entries = vim.tbl_map(function(entry)
    local display = string.format('%s: %s', entry.key, entry.title or '[no title]')
    return {
      key = entry.key,
      display = display,
      text = vim.inspect(entry),
      raw = entry,
    }
  end, entries)

  vim.notify(string.format('[bibcite] Loaded %d BibTeX entries.', #M.entries))
end

return M
