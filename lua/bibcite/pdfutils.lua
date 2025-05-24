-- Utilities for opening associated files (PDFs etc)

local config = require 'bibcite.config'

local M = {}

-- bib entries that have a 'path' field often have them in weird formats.
-- This function normalises them into an absolutely formed path.
function M.resolve_pdf_path(field)
  if not field or field == '' then
    return nil
  end

  local path = field:match '{:(.-):' or field
  if path:match '^/' then
    -- If the path is already absolute, e.g. `/home/my_user/pdfs/Smith2020.pdf`,
    -- Then just return the path as is.
    return path -- already absolute
  elseif path:match '^files' or path:match '^:files' then
    -- Jabref has functionality to link files in a central directory.
    -- It prefixes the path with ':files'.
    -- e.g. `{:files/Sakai2004.pdf:PDF}`
    -- We simulate this substitution by stripping this prefix,
    -- and inserting the directory you have set in the config.
    -- note that there is also an ending :PDF.
    -- This is a file hint.
    -- Just remove that, for now we assume everything is openable with
    -- a pdf viewer.
    local subpath = path:gsub('^:?files/?', '')
    return config.options.pdf_dir .. '/' .. subpath
  else
    -- TODO: Expand relative path '~/pdfs/Smith2020.pdf'
    return path
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
