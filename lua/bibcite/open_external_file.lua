-- Utilities for opening associated files (PDFs etc)

local config = require 'bibcite.config'
local bibtex = require 'bibcite.bibtex'

local M = {}

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
    local mode = config.options.note_open_mode
    if mode == 'hsplit' then
      vim.cmd('split ' .. vim.fn.fnameescape(path))
    elseif mode == 'vsplit' then
      vim.cmd('vsplit ' .. vim.fn.fnameescape(path))
    else
      vim.cmd('edit ' .. vim.fn.fnameescape(path))
    end
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

  -- TODO: Also add checking for a non-bibtex standard 'notes' field.

  -- TODO: Instead of checking all the files, cache all the notes and PDFs. Still do this as a separate step from loading the plugin, to not make it too slow to startup.
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
  local entry = bibtex.entries[key]

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

-- Helper: Prompt user and create a new note file
local function prompt_and_create_note_file(citekey)
  local suggested_path = string.format('%s/%s.md', config.options.notes_dir, citekey:lower())
  local answer = vim.fn.input(string.format("No note file exists yet for '%s'. Create it? [y/N]: ", citekey))

  if answer:lower() ~= 'y' then
    vim.notify('[bibcite] Note creation cancelled.', vim.log.levels.INFO)
    return
  end

  -- Ensure notes directory exists
  vim.fn.mkdir(config.options.notes_dir, 'p')

  -- Create and initialize the note file
  local fd = io.open(suggested_path, 'w')
  if not fd then
    vim.notify('[bibcite] Failed to create note file: ' .. suggested_path, vim.log.levels.ERROR)
    return
  end

  fd:write(string.format('# Notes for %s\n\n', citekey))
  fd:close()

  -- Open it in a new buffer
  vim.cmd('edit ' .. vim.fn.fnameescape(suggested_path))
end

-- Checks if the entry under the cursor has a note file, and opens it if it does.
-- If it doesn't prompts you to create a new one.
function M.open_note_of_refentry_under_cursor()
  local key = vim.fn.expand '<cword>'
  local entry = bibtex.entries[key]

  if not entry then
    vim.notify('[bibcite] No BibTeX entry for key: ' .. key, vim.log.levels.INFO)
    return
  end

  local note_path = resolve_note_path(entry.key)
  if note_path then
    open_external_file(note_path)
  else
    prompt_and_create_note_file(entry.key)
  end
end

return M
