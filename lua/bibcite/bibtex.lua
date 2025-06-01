-- Functionality for loading and parsing a .bib file

local config = require 'bibcite.config'
local M = {}

-- Optimized brace counting function
local function update_brace_level(line, current_level)
  for i = 1, #line do
    local c = line:sub(i, i)
    if c == '{' then
      current_level = current_level + 1
    elseif c == '}' then
      current_level = current_level - 1
    end
  end
  return current_level
end

-- Helper to extract a balanced value starting at position 'start_pos' in 'str'
local function extract_balanced_value(str, start_pos)
  local pos = start_pos
  local len = #str

  if str:sub(pos, pos) == '{' then
    local brace_count = 1
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
    return str:sub(value_start, pos - 2), pos
  elseif str:sub(pos, pos) == '"' then
    pos = pos + 1
    local value_start = pos
    while pos <= len and str:sub(pos, pos) ~= '"' do
      pos = pos + 1
    end
    return str:sub(value_start, pos - 1), pos + 1
  else
    local value_start = pos
    while pos <= len and str:sub(pos, pos) ~= ',' do
      pos = pos + 1
    end
    return str:sub(value_start, pos - 1), pos
  end
end

-- Parse .bib into an array of entries.
-- Each entry has fields  like they are in the .bib file.
-- In addition, it has a field for the citekey as well.
-- Returns a dictionary of citekey-citationdata
local function parse_bibtex(file)
  local entries = {}
  local current_entry_lines = {}
  local brace_level = 0
  local inside_entry = false

  -- Have these here so that hopefully the JIT picks up on it and
  -- re-uses them instead of re-assessing the pattern every single time.
  local entry_pattern = '^@(%w+)%s*{%s*([^,%s]+)'
  local exit_pattern = '([%w_]+)%s*=%s*'

  for line in io.lines(file) do
    if not inside_entry and line:match '^@' then
      current_entry_lines = { line }
      brace_level = update_brace_level(line, 0)
      inside_entry = true
    elseif inside_entry then
      table.insert(current_entry_lines, line)
      brace_level = update_brace_level(line, brace_level)

      if brace_level <= 0 then
        local current_entry = table.concat(current_entry_lines, '\n')
        local entry = {}

        local entry_type, key = current_entry:match(entry_pattern)
        if entry_type and key then
          entry.key = key
          entry.type = entry_type

          local pos = 1
          while true do
            local field_start, field_end, field = current_entry:find(exit_pattern, pos)
            if not field_start then
              break
            end
            pos = field_end + 1

            local value, new_pos = extract_balanced_value(current_entry, pos)
            if field and value then
              entry[field:lower()] = value
            end
            pos = new_pos
          end

          entries[key] = entry
        end

        current_entry_lines = {}
        inside_entry = false
      end
    end
  end

  return entries
end

-- Loads the default bibliography as set in the config, and adds it to the module.
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

  -- TODO: If there is a .bib file in the curren pwd, open that.
  -- TODO: support opening multiple .bib files, appending their results while ignoring duplicates.

  -- When load_bib has been run, make all of the loaded things
  -- accessible whenever you access this variable.
  M.entries = entries

  vim.notify(string.format('[bibcite] Loaded %d BibTeX entries.', #entries))
end

-- Debug utility to print loaded entries
function M.debug_print_entries()
  if not M.entries then
    print '[bibcite] No entries loaded'
    return
  end
  for _, entry in pairs(M.entries) do
    print(vim.inspect(entry))
  end
end

return M
