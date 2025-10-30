# 📚 bibcite.nvim
**bibcite.nvim** is a lightweight Neovim plugin designed to make your academic and research workflow more fluid.
Quickly search through your bibliography, open associated notes, or open files- all from within your favourite editor!

# Features
- Insert citation keys with Telescope (fzf-lua integration planned)
- Open external files (PDF, epub, whatever floats your boat) associated with BibTeX entries in your preferred file viewer.
- Quickly view, navigate to, and edit or create Markdown/text notes linked to a citation.
- Popup previews with author/title/year and quick note preview.
- Fully configurable paths and behavior.

See the demo below!
[![Bibcite.nvim Demo](https://img.youtube.com/vi/dwAJq2JPf_w/0.jpg)](https://www.youtube.com/watch?v=dwAJq2JPf_w)


# Purpose
**bibcite.nvim** provides fast and simple access to BibTeX citation data and related materials such as associated files and notes while working inside Neovim.
This plugin is **not** a comprehensive reference manager, but is instead intended to be used together with a tool that either directly saves as .bib (like [Bibiman](https://codeberg.org/lukeflo/bibiman) or JabRef), or exports to it (like Zotero or Mendeley).

This plugin is **read-only** when it comes to BibTeX entries: it won't let you add, delete, or modify entries within Neovim.
This way it stays minimal, simple, and fast.
It merely complements your existing reference workflow by integrating citation lookup, file access, and note-taking into the editor you already use.

Instead, **bibcite.nvim** is for users who:
- Already manage their .bib file with some other tool
- Want to insert citation keys into their writing quickly
- Like putting references to literature outside of latex documents, such as in code comments.
- Write notes on their literature in plain-text or Markdown

This plugin has great synergy when using something like [markdown-oxide](https://github.com/Feel-ix-343/markdown-oxide) or [obsidian.nvim](https://github.com/epwalsh/obsidian.nvim).

# Installation
Install using your preferred package manager.

## Lazy.nvim
```lua
{
  'aidavdw/bibcite.nvim',
  -- Running these commands triggers lazy load. They are still auto-completed.
  cmd = { 'CiteOpen', 'CiteInsert', 'CitePeek', 'CiteNote' },
  -- Hitting these keybinds triggers lazy-load. They still show up in which-keys.
  keys = {
    { '<leader>ci', ':CiteInsert<CR>', desc = 'Insert citation' },
    { '<leader>cp', ':CitePeek<CR>', desc = 'Peek citation info' },
    { '<leader>co', ':CiteOpen<CR>', desc = 'Open citation file' },
    { '<leader>cn', ':CiteNote<CR>', desc = 'Open citation note' },
  },
  -- Configuration goes here! See the config section.
  opts = {
    -- This is just an example
    bibtex_path = '~/Documents/research/references.bib',
    pdf_dir = '~/Documents/research/papers',
    notes_dir = '~/Documents/research/notes',
    text_file_open_mode = 'vsplit',
  }
}
```

## packer.nvim
```lua
use {
  'aidavdw/bibcite.nvim',
  config = function()
    require('bibcite').setup {
      -- same options as above
    }
  end,
}
```

# Configuration
The following configuration keys can be set:
```lua
{
  -- When the plugin is loaded, it will always load the .bib file on this path
  bibtex_path = nil,

  -- If you have a central directory where you keep all your PDFs (or other source/associated materials), put it here.
  pdf_dir = nil,

  -- Directory where notes are saved (named after citekey)
  notes_dir = nil,

  -- How to open notes or linked text files
  -- Options: "current", "hsplit", "vsplit"
  text_file_open_mode = 'current', 
}
```

# Commands
Command	Description
- `:CiteInsert` - Use Telescope to pick and insert a citation key at the cursor.
- `:CitePeek` - Show a popup preview of the citation under the cursor (author, title, year, PDF/note status).
- `:CiteOpen` - Open the PDF or external file linked to the citation under the cursor. If the file is a text-like file, it will be opened in neovim directly. If it is not, it will open it in an external program, using your preferred file viewer.
- `:CiteNote` - Open the note file for the citation under the cursor (prompts to creates one if missing).
- `:CiteList` - List all entries in Telescope. From this list, you can use keybindings to open the PDF (<C-o>), open the note (<C-n>), or open the entry in the bibtex source file (<C-s>).

# File Matching
When you invoke `:CiteOpen`, or `:CiteNote` the plugin looks for the associated file in the following order.
If a `file` is set in the `.bib` file, it takes precedence over a file in the central directory.

## 1. `file` field
Reads the field actually set in the .bib entry:
```bib
@Article{Smith2020,
  author     = {Smith, John and Doe, Jane},
  title      = {An examplary paper to set an example},
  year       = {2020},
  file       = "..."
```
This field may contain:
- An absolute path to the file (`/home/user/papers/Smith2020.pdf`, `~/papers/Smith2020.pdf`)
- A relative path from the `pdf_dir` to the file (`papers/Smith2020.pdf`)
- A JabRef-style hint: `:files/Sakai2004.pdf:PDF`, interpreted as relative to the `pdf_dir`. 

This is not implemented yet for the `note` field yet. Let me know if you'd think this is useful!


## 2. Central directory
This is a fallback for if no file field is found, as well as the standard method to locate notes.
The plugin will search inside `pdf_dir` and `notes_dir`set in the config.
If it finds a case-insensitive match using the **citekey**, it will be registered as a linked file.
It will try to match to a variety of extensions and capitalisations:
In `pdf_dir`: `smith2020.pdf`, `Smith2020.epub`, `SMITH2020.djvu`.
In `notes_dir`: `smith2020.md`, `Smith2020.org`, `SMITH2020.txt`.

# Loading `.bib` files
On startup, the file set in the config as `bibtex_path` will be automatically loaded.
In addition, any `.bib` files in the current working directory will also be loaded.

# Requirements
Requirements
- Neovim 0.8+
- xdg-open or open (for opening external files)
- [telescope.nvim](https://github.com/nvim-telescope/telescope.nvim) (optional, for :CiteInsert)

# License
This plugin is licensed under GPLv3 
