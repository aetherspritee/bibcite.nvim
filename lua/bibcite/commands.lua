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
function M.pick_entry(prompt_title)
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

  return coroutine.create(function(co)
    pickers
      .new({}, {
        prompt_title = prompt_title,
        finder = finders.new_table {
          results = bibtex.entries,
          entry_maker = function(entry)
            local display = format_display(entry)
            local search_text = table.concat({ entry.key, entry.author, entry.title, entry.year, entry.journal }, ' ')
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
            coroutine.resume(co, selection and selection.value or nil)
          end)
          return true
        end,
      })
      :find()

    local selected = coroutine.yield()
    return selected
  end)
end

-- Register Neovim commands
function M.setup()
  -- Create :CiteInsert command to insert citation key into buffer
  vim.api.nvim_create_user_command('CiteInsert', function()
    local co = M.pick_entry 'Insert Citation'
    if co and coroutine.status(co) == 'suspended' then
      coroutine.resume(co)
    end
    coroutine.wrap(function()
      local selected = coroutine.yield()
      if selected then
        vim.api.nvim_put({ selected.key }, '', true, true) -- insert key into buffer
      end
    end)()
  end, {})
end

return M
