# fff-snacks.nvim

A [snacks.nvim](https://github.com/folke/snacks.nvim) source for [fff.nvim](https://github.com/dmtrKovalenko/fff.nvim).

## Installation

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
    opts = {},
    keys = {
      { "<leader><leader>", "<CMD>FFFSnacks<CR>", desc = "FFF", }
    },
  },
}
```

## Configuration

You can customize the picker by passing options to the `setup()` function. All `snacks.picker.Config` options are supported.

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

### Runtime Override

You can override the layout when calling the picker:

```lua
-- Via Lua API with custom layout
:lua Snacks.picker.fff({ layout = "telescope" })
```
