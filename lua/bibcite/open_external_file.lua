-- Utilities for opening associated files (PDFs etc)

local config = require 'bibcite.config'
local bibtex = require 'bibcite.bibtex'

local M = {}

-- Helper to find entry by citekey
local function find_bib_entry_by_key(key)
  for _, entry in ipairs(bibtex.entries or {}) do
    if entry.key == key then
      return entry
    end
  end
end

-- bib entries that have a 'path' field often have them in weird formats.
-- This function normalises them into an absolutely formed path.
local function resolve_pdf_field_path(field)
  if not field or field == '' then
    return nil
  end

  -- Remove any JabRef-type suffix like :PDF
  -- This is a file hint.
  -- Just remove that, for now we assume everything is openable with
  -- a pdf viewer.
  local raw_path = field:match '{:(.-):' or field
  raw_path = raw_path:gsub(':%w+$', '') -- strip :PDF, :DOCX etc.

  -- Expand tilde to home directory
  if raw_path:sub(1, 2) == '~/' then
    raw_path = vim.fn.expand(raw_path)
  end

  -- If the path is already absolute, e.g. `/home/my_user/pdfs/Smith2020.pdf`,
  -- Then just return the path as is.
  if raw_path:sub(1, 1) == '/' then
    return raw_path
  elseif raw_path:match '^:?files/' then
    -- JabRef-style path (starts with files/ or :files/)
    -- Jabref has functionality to link files in a central directory.
    -- It prefixes the path with ':files'.
    -- e.g. `{:files/Sakai2004.pdf:PDF}`
    -- We simulate this substitution by stripping this prefix,
    -- and inserting the directory you have set in the config.
    local subpath = raw_path:gsub('^:?', ''):gsub('^files/', '')
    return config.options.pdf_dir .. '/' .. subpath

  -- Default fallback (relative or malformed path)
  else
    return raw_path
  end
end

-- Opens (external) file (note or PDF).
-- Opens them in an nvim buffer if they are text.
-- If a PDF or something, opens an external program using xdg-open.
local function open_external_file(path)
  if not path then
    return
  end

  local ext = path:match '^.+(%..+)$' or ''
  local is_text = ext == '.md' or ext == '.txt' or ext == '.org'

  if is_text then
    -- TODO: Allow setting in user settings if you prefer opening in current buffer, vsplit, whatever.
    vim.cmd('edit ' .. vim.fn.fnameescape(path))
  else
    if vim.fn.executable 'xdg-open' == 1 then
      vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
    elseif vim.fn.has 'macunix' == 1 then
      vim.fn.jobstart({ 'open', path }, { detach = true })
    else
      vim.notify('[bibcite] No supported file opener found', vim.log.levels.ERROR)
    end
  end
end

-- Checks for a note file for the given citekey. (e.g., smith2020.md)
local function resolve_note_path(key)
  local dir = config.options.notes_dir
  local extensions = { '.md', '.txt', '.org' }

  -- TODO: Also look in notes field.
  -- TODO: If no notes file exists yet, prompt to create new notes file.

  for _, ext in ipairs(extensions) do
    local variants = {
      string.format('%s/%s%s', dir, key, ext),
      string.format('%s/%s%s', dir, key:lower(), ext),
    }
    for _, path in ipairs(variants) do
      if vim.fn.filereadable(path) == 1 then
        return path
      end
    end
  end

  return nil
end

-- Checks if the entry under the cursor has an associated file (PDF), and opens it if it does.
function M.open_external_file_of_refentry_under_cursor()
  local key = vim.fn.expand '<cword>'
  local entry = find_bib_entry_by_key(key)

  if not entry then
    vim.notify('[bibcite] No BibTeX entry for key: ' .. key, vim.log.levels.INFO)
    return
  end

  local path = resolve_pdf_field_path(entry.file)
  if path and vim.fn.filereadable(path) == 1 then
    open_external_file(path)
  else
    vim.notify('[bibcite] File not found: ' .. (path or 'nil'), vim.log.levels.WARN)
  end
end

-- Checks if the entry under the cursor has a note file, and opens it if it does.
function M.open_note_of_refentry_under_cursor()
  local key = vim.fn.expand '<cword>'
  local entry = find_bib_entry_by_key(key)

  if not entry then
    vim.notify('[bibcite] No BibTeX entry for key: ' .. key, vim.log.levels.INFO)
    return
  end

  local path = resolve_note_path(entry.key)
  if path then
    open_external_file(path)
  else
    vim.notify('[bibcite] Note not found for key: ' .. entry.key, vim.log.levels.WARN)
  end
end

return M
