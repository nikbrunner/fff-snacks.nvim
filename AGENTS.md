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

**Finder Function** (lua/fff-snacks.lua:72-128)

- Initializes fff file picker if needed
- Manages current file caching for frecency calculations
- Transforms fff search results into snacks picker items
- Maps fff git status strings to snacks status objects
- Attaches score data from fff.nvim to each item for display

**Format Function** (lua/fff-snacks.lua:190-248)

- Handles git status highlighting using configurable `M.git_icons`
- Shows clean file icon (default: space) for unchanged files for consistent alignment
- Renders filename with appropriate highlights
- Displays right-aligned frecency score with visual indicator (if enabled)
- Visual indicators: 🔥 (hot), ⚡ (warm), ● (medium), ○ (cold)
- Follows snacks.nvim highlighting conventions

**Git Status Mapping**

- `staged_status` table (line 13): Defines which fff git statuses are "staged"
- `status_map` table (line 20): Maps fff status strings to snacks status strings
- Custom formatter `format_file_git_status` (line 36): Handles status icons and highlight groups

### Important Implementation Details

**HACK at line 111**: The status field is set to a table (with `status`, `staged`, `unmerged` fields) rather than the string that snacks.nvim's git implementation uses. This is intentional to work with fff.nvim's status format.

**Current File Caching**: The `current_file_cache` is initialized in the finder (not `on_show`) because finder is called before `on_show`. This cache is cleared in `on_close` to prevent stale data.

**Score Display**: Each picker line shows a right-aligned frecency score from fff.nvim's scoring system. The score reflects file access history and recency, helping you quickly identify frequently used files.

- Example line: ` M  filename.lua    common/.config/nvim    68`

**Git Icons Configuration** (lua/fff-snacks.lua:13-20): Git status icons are configurable via `M.git_icons`. Defaults use standard git letters (M, A, D, R, ?, !, space). Users can override these in `setup({ git_icons = {...} })` to use nerd font icons or custom symbols.

**Frecency Indicators Configuration** (lua/fff-snacks.lua:22-37): Visual indicators for file access frequency. Configurable via `M.frecency_indicators` with:
- Icons: hot (🔥), warm (🧨), medium (💧), cold (space)
- Thresholds: hot >= 50, warm >= 25, medium >= 10
- Indicator appears after the score on the right side
- Can be disabled or customized with different icons/thresholds
- Example line with indicator: ` M  filename.lua    common/.config/nvim    68 🔥`

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

The plugin accepts a `fff-snacks.Config` in the `setup()` function, which extends `snacks.picker.Config` with additional options:
- `git_icons`: `fff-Snacks.GitIcons` - Custom git status icon configuration
- `frecency_indicators`: `fff-snacks.FrecencyIndicators` - Visual indicators for file access frequency

Type definitions are available in lua/fff-snacks.lua (lines 13-37) for LSP autocomplete and type checking.

### Setup Configuration

**Basic setup with options**:

```lua
require("fff-snacks").setup({
  layout = "telescope",  -- Use built-in layout preset
  git_icons = {
    modified = "",     -- Customize git status icons
    clean = "",        -- Icon for unchanged files
  },
  frecency_indicators = {
    enabled = true,      -- Enable visual indicators
    hot = "🔥",          -- Icon for highly accessed files
    thresholds = {       -- Customize score thresholds
      hot = 50,
      warm = 30,
      medium = 10,
    }
  },
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
