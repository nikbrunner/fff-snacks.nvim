# fff-snacks.nvim

A [snacks.nvim](https://github.com/folke/snacks.nvim) source for [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim).

## Features

- **Frecency-based file finding** - Leverages fff.nvim's Rust-powered frecency scoring
- **Score display** - Shows frecency score for each file on the right side
- **Flexible layouts** - Use built-in snacks.nvim presets or create custom layouts
- **Git integration** - Visual git status indicators with colored icons

### Picker Display

Each file entry shows:

- **Left**: Git status icon (defaults: M/A/D/R/?/!, space for clean files)
- **Center**: Filename and directory path
- **Right**: Frecency score (reflects access history and recency)

Example (with default git letter icons):

```
M  filename.lua        common/.config/nvim       68
?  new-file.ts         src/components            12
   settings.json       common/.config            89
```

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
