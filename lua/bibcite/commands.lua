local bibtex = require 'bibcite.bibtex'

local M = {}

-- Format how each BibTeX entry is displayed in Telescope
local function format_display(entry)
  local parts = {}
  if entry.key then
    table.insert(parts, string.format('[%s]', entry.key))
  end
  if entry.author then
    table.insert(parts, entry.author)
  end
  if entry.year then
    table.insert(parts, string.format('(%s)', entry.year))
  end
  if entry.title then
    table.insert(parts, ': ' .. entry.title)
  end
  return table.concat(parts, ' ')
end

-- Reusable Telescope picker function to select a BibTeX entry
-- Accepts a prompt_title and a callback to call with the selected entry
function M.pick_entry(prompt_title, on_select)
  local has_telescope, telescope = pcall(require, 'telescope')
  if not has_telescope then
    vim.notify('[bibcite] Telescope is not available', vim.log.levels.ERROR)
    return
  end

  local pickers = require 'telescope.pickers'
  local finders = require 'telescope.finders'
  local conf = require('telescope.config').values
  local actions = require 'telescope.actions'
  local action_state = require 'telescope.actions.state'

  pickers
    .new({}, {
      prompt_title = prompt_title,
      finder = finders.new_table {
        results = bibtex.entries,
        entry_maker = function(entry)
          local display = format_display(entry)
          local search_text = table.concat({
            entry.key or '',
            entry.author or '',
            entry.title or '',
            entry.year or '',
            entry.journal or '',
          }, ' ')
          return {
            value = entry,
            display = display,
            ordinal = search_text,
          }
        end,
      },
      sorter = conf.generic_sorter {},
      attach_mappings = function(_, map)
        actions.select_default:replace(function()
          local selection = action_state.get_selected_entry()
          actions.close(_)
          if selection and on_select then
            on_select(selection.value)
          end
        end)
        return true
      end,
    })
    :find()
end

-- Register Neovim commands
function M.setup()
  -- Create :CiteInsert command to insert citation key into buffer
  vim.api.nvim_create_user_command('CiteInsert', function()
    M.pick_entry('Insert Citation', function(entry)
      if entry then
        vim.api.nvim_put({ entry.key }, '', true, true)
      end
    end)
  end, {})
end

return M
