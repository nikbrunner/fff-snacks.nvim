---@module 'snacks'

---@class snacks.picker.sources.Config
---@field fff snacks.picker.Config
---@field fff_live_grep FFFSnacksGrepConfig

---@class snacks.picker
---@field fff fun(opts?: snacks.picker.Config): snacks.Picker
---@field fff_live_grep fun(opts?: FFFSnacksGrepConfig): snacks.Picker

---@alias FFFGrepMode "plain" | "regex" | "fuzzy"

---@class FFFSnacksGrepConfig: snacks.picker.Config
---@field grep_mode? FFFGrepMode[]
---@field _is_grep_mode_plain? boolean
---@field _is_grep_mode_regex? boolean
---@field _is_grep_mode_fuzzy? boolean

---@class FFFSnacksGrepPicker: snacks.Picker
---@field opts FFFSnacksGrepConfig

---@class fff-Snacks.GitIcons
---@field modified? string Icon for modified files (default: "M")
---@field added? string Icon for added/staged new files (default: "A")
---@field deleted? string Icon for deleted files (default: "D")
---@field renamed? string Icon for renamed files (default: "R")
---@field untracked? string Icon for untracked files (default: "?")
---@field ignored? string Icon for ignored files (default: "!")
---@field clean? string Icon for clean/unchanged files (default: " ")

---@class fff-snacks.FrecencyThresholds
---@field hot? number Threshold for hot indicator (default: 50)
---@field warm? number Threshold for warm indicator (default: 25)
---@field medium? number Threshold for medium indicator (default: 10)

---@class fff-snacks.FrecencyIndicators
---@field enabled? boolean Enable frecency indicators (default: true)
---@field hot? string Icon for very high scores (default: "🔥")
---@field warm? string Icon for high scores (default: "🧨")
---@field medium? string Icon for medium scores (default: "💧")
---@field cold? string Icon for low scores (default: " ")
---@field thresholds? fff-snacks.FrecencyThresholds Score thresholds

---@class fff-snacks.Config: snacks.picker.Config
---@field git_icons? fff-Snacks.GitIcons Custom git status icons
---@field frecency_indicators? fff-snacks.FrecencyIndicators Visual indicators for frecency scores

local M = {
  sources = {
    find_files = require("fff-snacks.find_files").source,
    live_grep = require("fff-snacks.live_grep").source,
  },
}

---@type fff-Snacks.GitIcons
local git_icons_defaults = {
  modified = "M",
  added = "A",
  deleted = "D",
  renamed = "R",
  untracked = "?",
  ignored = "!",
  clean = " ",
}

---@type fff-snacks.FrecencyIndicators
local frecency_defaults = {
  enabled = true,
  hot = "🔥",
  warm = "🧨",
  medium = "💧",
  cold = " ",
  thresholds = {
    hot = 50,
    warm = 25,
    medium = 10,
  },
}

--- Setup the fff-snacks plugin
---@param opts? fff-snacks.Config Configuration options to customize the picker
function M.setup(opts)
  opts = opts or {}

  -- Merge custom git icons if provided
  if opts.git_icons then
    require("fff-snacks.find_files").git_icons =
      vim.tbl_deep_extend("force", git_icons_defaults, opts.git_icons)
    opts.git_icons = nil -- Remove from opts so it doesn't get passed to snacks
  end

  -- Merge custom frecency indicators if provided
  if opts.frecency_indicators then
    require("fff-snacks.find_files").frecency_indicators =
      vim.tbl_deep_extend("force", frecency_defaults, opts.frecency_indicators)
    opts.frecency_indicators = nil -- Remove from opts so it doesn't get passed to snacks
  end

  return opts
end

---@param opts? snacks.picker.Config
function M.find_files(opts)
  local merged_opts = M.setup(opts)
  Snacks.picker.fff(merged_opts)
end

---@param opts? FFFSnacksGrepConfig
function M.live_grep(opts)
  Snacks.picker.fff_live_grep(opts)
end

---@param opts? FFFSnacksGrepConfig
function M.grep_word(opts)
  opts = opts or {}
  opts.search = function(picker)
    return picker:word()
  end
  Snacks.picker.fff_live_grep(opts)
end

return M
