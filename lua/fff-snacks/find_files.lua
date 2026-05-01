-- maps to require("fff").find_files()

local M = {}

local utils = require "fff-snacks.utils"

local conf = require "fff.conf"
local file_picker = require "fff.file_picker"

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

--- Default git status icons (can be overridden in setup)
---@type fff-Snacks.GitIcons
M.git_icons = {
  modified = "M",
  added = "A",
  deleted = "D",
  renamed = "R",
  untracked = "?",
  ignored = "!",
  clean = " ",
}

--- Default frecency indicators (can be overridden in setup)
---@type fff-snacks.FrecencyIndicators
M.frecency_indicators = {
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

local staged_status = {
  staged_new = true,
  staged_modified = true,
  staged_deleted = true,
  renamed = true,
}

local status_map = {
  untracked = "untracked",
  modified = "modified",
  deleted = "deleted",
  renamed = "renamed",
  staged_new = "added",
  staged_modified = "modified",
  staged_deleted = "deleted",
  ignored = "ignored",
  unknown = "untracked",
  -- clean and clear are intentionally unmapped so files with no git changes
  -- fall through to the neutral "clean file" display (M.git_icons.clean)
  -- rather than getting colored git status highlighting
}

--- Format git status using configurable icons
--- @type snacks.picker.format
local function format_file_git_status(item, picker)
  local ret = {} ---@type snacks.picker.Highlight[]
  local status = item.status

  local hl = "SnacksPickerGitStatus"
  if status.unmerged then
    hl = "SnacksPickerGitStatusUnmerged"
  elseif status.staged then
    hl = "SnacksPickerGitStatusStaged"
  else
    hl = "SnacksPickerGitStatus" .. status.status:sub(1, 1):upper() .. status.status:sub(2)
  end

  -- Use configurable git icons
  local icon
  if status.status == "modified" then
    icon = M.git_icons.modified
  elseif status.status == "added" then
    icon = M.git_icons.added
  elseif status.status == "deleted" then
    icon = M.git_icons.deleted
  elseif status.status == "renamed" then
    icon = M.git_icons.renamed
  elseif status.status == "untracked" then
    icon = M.git_icons.untracked
  elseif status.status == "ignored" then
    icon = M.git_icons.ignored
  else
    icon = M.git_icons.clean
  end

  ret[#ret + 1] = { icon, hl }
  ret[#ret + 1] = { " ", virtual = true }

  ret[#ret + 1] = {
    col = 0,
    virt_text = { { status.status:sub(1, 1):upper(), hl }, { " " } },
    virt_text_pos = "right_align",
    hl_mode = "combine",
  }
  return ret
end

---@type snacks.picker.Config
M.source = {
  title = "FFFiles",
  finder = function(opts, ctx)
    -- fff.picker_ui: initialize_picker
    if not file_picker.is_initialized() then
      if not file_picker.setup() then
        vim.notify("Failed to initialize file picker", vim.log.levels.ERROR)
        return {}
      end
    end

    local config = conf.get()
    local merged_config = vim.tbl_deep_extend("force", config or {}, opts or {})
    if not merged_config then
      return {}
    end

    local base_path = opts.cwd or vim.uv.cwd()
    if not base_path then
      return {}
    end

    local current_file = utils.get_current_file(base_path)

    local fff_result = file_picker.search_files(
      ctx.filter.search,
      current_file,
      opts.limit or merged_config.max_results,
      merged_config.max_threads,
      nil
    )

    ---@type snacks.picker.finder.Item[]
    local items = {}
    local seen = {} ---@type table<string, boolean>
    for idx, fff_item in ipairs(fff_result) do
      -- Skip duplicate files (fff.nvim may return the same path multiple times)
      if seen[fff_item.relative_path] then
        goto continue
      end
      seen[fff_item.relative_path] = true
      ---@type snacks.picker.finder.Item
      local item = {
        text = fff_item.name,
        file = fff_item.relative_path,
        score = fff_item.total_frecency_score,
        -- HACK: in original snacks implementation status is a string of
        -- `git status --porcelain` output
        status = status_map[fff_item.git_status] and {
          status = status_map[fff_item.git_status],
          staged = staged_status[fff_item.git_status] or false,
          unmerged = fff_item.git_status == "unmerged",
        },
        -- Attach fff-specific data for the format function
        fff_item = fff_item,
      }
      items[#items + 1] = item
      ::continue::
    end

    return items
  end,
  format = function(item, picker)
    ---@type snacks.picker.Highlight[]
    local ret = {}

    if item.label then
      ret[#ret + 1] = { item.label, "SnacksPickerLabel" }
      ret[#ret + 1] = { " ", virtual = true }
    end

    if item.status then
      vim.list_extend(ret, format_file_git_status(item, picker))
    else
      -- Show unchanged/clean file icon for consistent alignment
      ret[#ret + 1] = { M.git_icons.clean, "Comment" }
      ret[#ret + 1] = { " ", virtual = true }
    end

    vim.list_extend(ret, require("snacks").picker.format.filename(item, picker))

    if item.line then
      require("snacks").picker.highlight.format(item, item.line, ret)
      table.insert(ret, { " " })
    end

    -- Add right-aligned score information with frecency indicator
    if item.fff_item then
      local fff_item = item.fff_item
      local score = fff_item.total_frecency_score
      local score_text = tostring(score)

      -- Add frecency indicator if enabled
      if M.frecency_indicators.enabled then
        local indicator
        local thresholds = M.frecency_indicators.thresholds

        if score >= thresholds.hot then
          indicator = M.frecency_indicators.hot
        elseif score >= thresholds.warm then
          indicator = M.frecency_indicators.warm
        elseif score >= thresholds.medium then
          indicator = M.frecency_indicators.medium
        else
          indicator = M.frecency_indicators.cold
        end

        score_text = score_text .. " " .. indicator
      end

      -- Right-align the score text
      ret[#ret + 1] = {
        col = 0,
        virt_text = { { score_text, "Comment" } },
        virt_text_pos = "right_align",
        hl_mode = "combine",
      }
    end

    return ret
  end,
  formatters = {
    file = {
      filename_first = true,
    },
  },
  live = true,
}

return M
