# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Neovim plugin that provides a snacks.nvim picker source for fff.nvim (a Rust-based fuzzy file finder with frecency scoring). It acts as a bridge between fff.nvim's fast file searching capabilities and snacks.nvim's picker UI.

## Architecture

### Core Integration Pattern

The plugin follows the snacks.nvim picker source pattern:

- **Source Definition** (`M.source`): Provides `finder`, `format`, and lifecycle hooks (`on_close`) that snacks.nvim expects
- **State Management** (`M.state`): Maintains current file cache and FFF config between searches
- **Setup Function** (`M.setup`): Registers the source with Snacks and creates the `FFFSnacks` user command

### Key Components

**Finder Function** (lua/fff-snacks.lua:72-123)
- Initializes fff file picker if needed
- Manages current file caching for frecency calculations
- Transforms fff search results into snacks picker items
- Maps fff git status strings to snacks status objects

**Format Function** (lua/fff-snacks.lua:124-146)
- Handles git status highlighting using custom `format_file_git_status`
- Renders filename with appropriate highlights
- Follows snacks.nvim highlighting conventions

**Git Status Mapping**
- `staged_status` table (line 13): Defines which fff git statuses are "staged"
- `status_map` table (line 20): Maps fff status strings to snacks status strings
- Custom formatter `format_file_git_status` (line 36): Handles status icons and highlight groups

### Important Implementation Details

**HACK at line 111**: The status field is set to a table (with `status`, `staged`, `unmerged` fields) rather than the string that snacks.nvim's git implementation uses. This is intentional to work with fff.nvim's status format.

**Current File Caching**: The `current_file_cache` is initialized in the finder (not `on_show`) because finder is called before `on_show`. This cache is cleared in `on_close` to prevent stale data.

## Development Commands

### Formatting

```bash
stylua lua/
```

Format Lua code according to .stylua.toml configuration (LuaJIT syntax, 120 column width, 2-space indents).

### Testing

This plugin should be tested manually in Neovim with:
1. fff.nvim installed and initialized
2. snacks.nvim loaded
3. Call `:FFFSnacks` or `Snacks.picker.fff()`

## Configuration

The plugin accepts any `snacks.picker.Config` options in the `setup()` function, allowing customization of layout, formatters, and other picker behavior.

### Setup Configuration

**Basic setup with options**:
```lua
require("fff-snacks").setup({
  layout = "telescope",  -- Use built-in layout preset
  -- Any other snacks.picker.Config options
})
```

### Layout Configuration

Layouts can be specified in multiple ways:

**Built-in preset names (string)**:
```lua
{
  layout = "telescope"
  -- Available presets defined in ~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/picker/config/layouts.lua:
  -- "default", "telescope", "ivy", "ivy_split", "sidebar", "dropdown",
  -- "vertical", "select", "vscode", "left", "right", "top", "bottom"
}
```

**Built-in preset with overrides**:
```lua
{
  layout = { preset = "ivy", layout = { height = 0.5 } }
}
```

**Custom layout configuration**:
```lua
{
  layout = {
    preview = "main",
    layout = {
      box = "vertical",
      border = "solid",
      width = 0.6,
      height = 0.8,
    }
  }
}
```

**Dynamic layout function**:
```lua
{
  -- Functions are re-evaluated on every picker invocation
  layout = function()
    return vim.o.columns >= 165 and "default" or "vertical"
  end
}
```

### Runtime Override

Layout (and other options) can be overridden when calling the picker:

```lua
-- Via Snacks API:
Snacks.picker.fff({ layout = "vscode" })

-- Via keymap with custom layout:
vim.keymap.set("n", "<leader>ff", function()
  Snacks.picker.fff({ layout = "telescope" })
end)

-- Or call the command (uses default from setup):
vim.cmd("FFFSnacks")
```

## Dependencies

- **fff.nvim**: Provides `fff.conf`, `fff.file_picker` modules
- **snacks.nvim**: Provides picker framework and formatting utilities
- Must be built with `cargo build --release` (fff.nvim requirement)
