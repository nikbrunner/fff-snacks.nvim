# fff-snacks.nvim

A [snacks.nvim](https://github.com/folke/snacks.nvim) source for [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim).

## Features

- **Frecency-based file finding** - Leverages fff.nvim's Rust-powered frecency scoring
- **Visual frecency indicators** - At-a-glance visual indicators (🔥⚡●○) showing file access frequency
- **Score display** - Shows frecency score for each file on the right side
- **Flexible layouts** - Use built-in snacks.nvim presets or create custom layouts
- **Git integration** - Visual git status indicators with colored icons
- **Highly customizable** - Configure git icons, frecency indicators, thresholds, and layouts

### Picker Display

Each file entry shows:

- **Left**: Git status icon (defaults: M/A/D/R/?/!, space for clean files)
- **Center**: Filename and directory path
- **Right**: Frecency score (reflects access history and recency)

Example (with default icons and frecency indicators):

```
M  filename.lua        common/.config/nvim      68 🔥
?  new-file.ts         src/components           12
   settings.json       common/.config           42 🧨
```

**Frecency Indicators:**
- 🔥 Hot (score >= 50) - Very frequently accessed files
- 🧨 Warm (score >= 25) - Frequently accessed files
- 💧 Medium (score >= 10) - Moderately accessed files
- (space) Cold (score < 10) - Rarely accessed files

## Installation

With [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
{
  {
    "dmtrKovalenko/fff.nvim",
    build = "cargo build --release",
    lazy = false, -- make fff initialize on startup
  },
  {
    "madmaxieee/fff-snacks.nvim",
    dependencies = { "dmtrKovalenko/fff.nvim", "folke/snacks.nvim" },
    ---@module "fff-snacks"
    ---@type fff-snacks.Config
    opts = {},
    keys = {
      { "<leader><leader>", "<CMD>FFFSnacks<CR>", desc = "FFF", }
    },
  },
}
```

## Configuration

You can customize the picker by passing options to the `setup()` function.  (`lazy.nvim` will handover `opts` to `setup()`)

All `snacks.picker.Config` options are supported and extended with configurations for `fff-snacks.nvim`.

### Layout Options

**Use a built-in preset**:

```lua
opts = {
  -- @see ~/.local/share/nvim/lazy/snacks.nvim/lua/snacks/picker/config/layouts.lua
  layout = "telescope" -- or "ivy", "vscode", "sidebar", etc.
}
```

**Use a custom layout function**:

```lua
opts = {
  -- When handing over a function, it will be re-evaluated on every call
  layout = function()
    -- Adaptive layout based on window width
    return vim.o.columns >= 165 and "default" or "vertical"
  end
}
```

**Use a custom layout configuration**:

```lua
opts = {
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

You can override the layout when calling the picker:

```lua
-- Via Lua API with custom layout
:lua Snacks.picker.fff({ layout = "telescope" })
```

### Git Status Icons

Customize the git status icons shown on the left side:

```lua
opts = {
  git_icons = {
    modified = "M",    -- or use nerd fonts like ""
    added = "A",       -- or ""
    deleted = "D",     -- or ""
    renamed = "R",     -- or ""
    untracked = "?",   -- or ""
    ignored = "!",     -- or ""
    clean = " ",       -- or "" for unchanged files
  }
}
```

**Defaults**: Uses standard git letters (M, A, D, R, ?, !, and space for clean files)

### Frecency Indicators

Customize the visual indicators that show how "hot" or frequently accessed files are:

```lua
opts = {
  frecency_indicators = {
    enabled = true,               -- Enable/disable indicators
    hot = "🔥",
    warm = "🧨",
    medium = "💧",
    cold = " ", -- Leave blank for no indicator
    thresholds = {
      hot = 50,                   -- Threshold for hot indicator
      warm = 30,                  -- Threshold for warm indicator
      medium = 10,                -- Threshold for medium indicator
    }
  }
}
```

**Defaults**: 🔥/🧨/💧/(space) with thresholds at 50/25/10

**Display**: Indicator appears after the score (e.g., `68 🔥`, `42 🧨`, `12 💧`)

**Examples:**
- Disable indicators: `frecency_indicators = { enabled = false }`
- Use nerd font icons: `hot = "", warm = "", medium = "", cold = ""`
- Adjust thresholds: `thresholds = { hot = 100, warm = 50, medium = 20 }`
