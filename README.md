# fff-snacks.nvim

A [snacks.nvim](https://github.com/folke/snacks.nvim) source for [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim).

## Features

- **Frecency-based file finding** - Leverages fff.nvim's Rust-powered frecency scoring
- **Visual frecency indicators** - At-a-glance visual indicators (🔥⚡💧○) showing file access frequency
- **Score display** - Shows frecency score for each file on the right side
- **Git integration** - Visual git status indicators with configurable icons
- **Live grep** - Fast content searching with plain/regex/fuzzy modes
- **Highly customizable** - Configure git icons, frecency indicators, thresholds, and layouts

### Picker Display

Each file entry shows:

- **Left**: Git status icon (defaults: M/A/D/R/?/!, space for clean files)
- **Center**: Filename and directory path
- **Right**: Frecency score (reflects access history and recency)

Example:

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
return {
  {
    "dmtrKovalenko/fff.nvim",
    build = function()
      require("fff.download").download_or_build_binary()
    end,
    lazy = false, -- make fff initialize on startup
  },
  {
    "nikbrunner/fff-snacks.nvim",
    dependencies = { "dmtrKovalenko/fff.nvim", "folke/snacks.nvim" },
    -- lazy = false, -- loaded by plugin/fff-snacks.lua on UIEnter
    keys = {
      {
        "<leader>ff",
        function()
          require("fff-snacks").find_files()
        end,
        desc = "FFF find files",
      },
      {
        "<leader>fw",
        function()
          require("fff-snacks").live_grep()
        end,
        desc = "FFF live grep",
      },
      {
        mode = "v",
        "<leader>fw",
        function()
          require("fff-snacks").grep_word()
        end,
        desc = "FFF grep word",
      },
      {
        "<leader>fz",
        function()
          require("fff-snacks").live_grep({
            grep_mode = { "fuzzy", "plain", "regex" },
          })
        end,
        desc = "FFF live grep (fuzzy)",
      },
    },
    -- Configuration via opts
    ---@type fff-snacks.Config
    opts = {},
  },
}
```

## Commands

- `:FFFSnacks` - Open file picker (same as `<leader>ff`)
- `:FFFSnacks find_files` - Open file picker (explicit)
- `:FFFSnacks live_grep` - Open live grep with plain/regex/fuzzy modes
- `:FFFSnacks fuzzy` - Open live grep in fuzzy mode

## Configuration

All `snacks.picker.Config` options are supported, plus:

### Layout Options

**Use a built-in preset**:

```lua
opts = {
  layout = "telescope" -- or "ivy", "vscode", "sidebar", etc.
}
```

**Use a custom layout function**:

```lua
opts = {
  layout = function()
    return vim.o.columns >= 165 and "default" or "vertical"
  end
}
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

Customize the visual indicators showing file access frequency:

```lua
opts = {
  frecency_indicators = {
    enabled = true,               -- Enable/disable indicators
    hot = "🔥",
    warm = "🧨",
    medium = "💧",
    cold = " ",                   -- Leave blank for no indicator
    thresholds = {
      hot = 50,                   -- Threshold for hot indicator
      warm = 25,                  -- Threshold for warm indicator
      medium = 10,                -- Threshold for medium indicator
    }
  }
}
```

**Display**: Indicator appears after the score (e.g., `68 🔥`, `42 🧨`, `12 💧`)

**Examples:**
- Disable indicators: `frecency_indicators = { enabled = false }`
- Use nerd font icons: `hot = "", warm = "", medium = "", cold = ""`
- Adjust thresholds: `thresholds = { hot = 100, warm = 50, medium = 20 }`

### Layout Configuration

**Custom layout configuration**:

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

### Runtime Override

Layout (and other options) can be overridden when calling the picker:

```lua
-- Via Lua API with custom layout
require("fff-snacks").find_files({ layout = "telescope" })
```

## Live Grep

The live grep supports three search modes that can be cycled with `<c-y>`:

- **plain** - Plain text search
- **regex** - Regular expression search
- **fuzzy** - Fuzzy search

Cycle through modes by pressing `<c-y>` in the input prompt.

## License

MIT
