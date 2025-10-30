-- Functionality for loading and parsing a .bib file

local config = require 'bibcite.config'
local M = {
  entries = {},
}

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

-- TODO: In titles/fields that {Use} {Curly Braces} {Everywhere}, strip the curly braces.
-- TODO: Ignore the 'jabref-meta' field- that one is still being loaded.

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
  local line_num = 0
  local entry_start_line = 0

  -- Have these here so that hopefully the JIT picks up on it and
  -- re-uses them instead of re-assessing the pattern every single time.
  local entry_pattern = '^@(%w+)%s*{%s*([^,%s]+)'
  local exit_pattern = '([%w_]+)%s*=%s*'

  for line in io.lines(file) do
    line_num = line_num + 1
    if not inside_entry and line:match '^@' then
      current_entry_lines = { line }
      brace_level = update_brace_level(line, 0)
      inside_entry = true
      entry_start_line = line_num
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
          entry.file_path = file
          entry.line_num = entry_start_line

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

--- Loads a .bib file from the given path and merges its entries into `M.entries`.
-- @param path string: Path to the .bib file
function M.load_bib_from_path(path)
  if not path or path == '' then
    vim.notify('[bibcite] No path provided for .bib file.', vim.log.levels.ERROR)
    return
  end

  local ok, new_entries = pcall(parse_bibtex, path)
  if not ok then
    vim.notify('[bibcite] Failed to load .bib file: ' .. new_entries, vim.log.levels.ERROR)
    return
  end

  local added, skipped = 0, 0

  for key, entry in pairs(new_entries) do
    if not M.entries[key] then
      M.entries[key] = entry
      added = added + 1
    else
      skipped = skipped + 1
    end
  end

  vim.notify(string.format('[bibcite] Loaded %d new entries from %s (%d duplicates ignored)', added, path, skipped), vim.log.levels.INFO)
end

-- Loads the default bibliography as set in the config, and adds it to the module.
function M.load_bib_from_config()
  local path = config.options.bibtex_path
  M.load_bib_from_path(path)
end

function M.load_all_bibs_in_pwd()
  local cwd = vim.fn.getcwd()
  local bib_files = vim.fn.glob(cwd .. '/*.bib', true, true)

  if vim.tbl_isempty(bib_files) then
    vim.notify('[bibcite] No .bib files found in current directory: ' .. cwd, vim.log.levels.DEBUG)
    return
  end

  for _, path in ipairs(bib_files) do
    M.load_bib_from_path(path)
  end
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

function M.open_bibtex_entry(entry)
  if entry.file_path and entry.line_num then
    vim.cmd('edit ' .. vim.fn.fnameescape(entry.file_path))
    vim.api.nvim_win_set_cursor(0, { entry.line_num, 0 })
  else
    vim.notify('[bibcite] No file path or line number for entry: ' .. entry.key, vim.log.levels.WARN)
  end
end

return M
