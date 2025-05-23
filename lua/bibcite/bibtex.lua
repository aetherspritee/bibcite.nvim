-- Functionality for loading and parsing a .bib file

local config = require 'bibcite.config'
local M = {}

-- Parse .bib file and return a list of structured entries
local function parse_bibtex(file)
  local entries = {}
  local current_entry = nil
  local brace_level = 0
  local inside_entry = false

  -- Helper to extract a balanced value starting at position 'start_pos' in 'str'
  local function extract_balanced_value(str, start_pos)
    local pos = start_pos
    local brace_count = 0
    local len = #str

    if str:sub(pos, pos) == '{' then
      brace_count = 1
      pos = pos + 1
      local value_start = pos
      while pos <= len and brace_count > 0 do
        local c = str:sub(pos, pos)
        if c == '{' then
          brace_count = brace_count + 1
        elseif c == '}' then
          brace_count = brace_count - 1
        end
        pos = pos + 1
      end
      -- Return the substring inside braces and the new position after closing brace
      return str:sub(value_start, pos - 2), pos
    elseif str:sub(pos, pos) == '"' then
      -- Find closing quote (no escape char support)
      pos = pos + 1
      local value_start = pos
      while pos <= len and str:sub(pos, pos) ~= '"' do
        pos = pos + 1
      end
      -- Return substring inside quotes and position after closing quote
      return str:sub(value_start, pos - 1), pos + 1
    else
      -- Fallback: read until next comma or end of string
      local value_start = pos
      while pos <= len and str:sub(pos, pos) ~= ',' do
        pos = pos + 1
      end
      return str:sub(value_start, pos - 1), pos
    end
  end

  for line in io.lines(file) do
    -- Detect start of entry
    if not inside_entry and line:match '^@' then
      current_entry = line
      -- Calculate initial brace count for the entry line
      brace_level = select(2, line:gsub('{', '')) - select(2, line:gsub('}', ''))
      inside_entry = true
    elseif inside_entry then
      -- Continue collecting entry lines
      current_entry = current_entry .. '\n' .. line
      brace_level = brace_level + select(2, line:gsub('{', '')) - select(2, line:gsub('}', ''))
      -- End of entry
      if brace_level <= 0 then
        local entry = {}
        -- Extract entry type and key
        local entry_type, key = current_entry:match '^@(%w+)%s*{%s*([^,%s]+)'
        if entry_type and key then
          entry.key = key
          entry.type = entry_type

          -- Now parse fields properly using the balanced-value extractor
          local pos = 1
          while true do
            -- Find next field name
            local field_start, field_end, field = current_entry:find('([%w_]+)%s*=%s*', pos)
            if not field_start then
              break
            end
            pos = field_end + 1

            -- Extract balanced field value
            local value, new_pos = extract_balanced_value(current_entry, pos)
            if field and value then
              entry[field:lower()] = value
            end
            pos = new_pos
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

-- Debug utility to print loaded entries
function M.debug_print_entries()
  if not M.entries then
    print '[bibcite] No entries loaded'
    return
  end
  for _, entry in ipairs(M.entries) do
    print(vim.inspect(entry))
  end
end

return M
