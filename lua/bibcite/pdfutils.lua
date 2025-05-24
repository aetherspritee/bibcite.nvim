-- Utilities for opening associated files (PDFs etc)

local config = require 'bibcite.config'

local M = {}

-- bib entries that have a 'path' field often have them in weird formats.
-- This function normalises them into an absolutely formed path.
function M.resolve_pdf_path(field)
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

-- Open the file with the given path with an external viewer.
function M.open_file(path)
  if vim.fn.executable 'xdg-open' == 1 then
    vim.fn.jobstart({ 'xdg-open', path }, { detach = true })
  elseif vim.fn.has 'macunix' == 1 then
    vim.fn.jobstart({ 'open', path }, { detach = true })
  else
    vim.notify('[bibcite] No supported file opener found', vim.log.levels.ERROR)
  end
end

-- TODO: Add opening of note, re-using code where possible.

return M
