local M = {}

local conf = require "fff.conf"
local file_picker = require "fff.file_picker"

---@class fff-snacks.State
---@field current_file_cache? string
---@field config table FFF config

---@type fff-snacks.State
M.state = { config = {} }

---@class fff-Snacks.GitIcons
---@field modified? string Icon for modified files (default: "M")
---@field added? string Icon for added/staged new files (default: "A")
---@field deleted? string Icon for deleted files (default: "D")
---@field renamed? string Icon for renamed files (default: "R")
---@field untracked? string Icon for untracked files (default: "?")
---@field ignored? string Icon for ignored files (default: "!")
---@field clean? string Icon for clean/unchanged files (default: " ")

---@class fff-snacks.Config: snacks.picker.Config
---@field git_icons? fff-Snacks.GitIcons Custom git status icons

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
  -- clean = "",
  -- clear = "",
}

--- Format git status using configurable icons
--- @type snacks.picker.format
local function format_file_git_status(item)
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

  return ret
end

---@type snacks.picker.Config
M.source = {
  title = "FFFiles",
  finder = function(opts, ctx)
    -- initialization code from require('fff.picker_ui').open
    -- on_show does not seem to be called before finder
    if not M.state.current_file_cache then
      local current_buf = vim.api.nvim_get_current_buf()
      if current_buf and vim.api.nvim_buf_is_valid(current_buf) then
        local current_file = vim.api.nvim_buf_get_name(current_buf)
        if current_file ~= "" and vim.fn.filereadable(current_file) == 1 then
          M.state.current_file_cache = current_file
        else
          M.state.current_file_cache = nil
        end
      end
    end
    if not file_picker.is_initialized() then
      if not file_picker.setup() then
        vim.notify("Failed to initialize file picker", vim.log.levels.ERROR)
        return {}
      end
    end
    local config = conf.get()
    M.state.config = vim.tbl_deep_extend("force", config or {}, opts or {})

    local fff_result = file_picker.search_files(
      ctx.filter.search,
      opts.limit or M.state.config.max_results,
      M.state.config.max_threads,
      M.state.current_file_cache,
      false
    )

    ---@type snacks.picker.finder.Item[]
    local items = {}
    for idx, fff_item in ipairs(fff_result) do
      -- Get score data from fff.nvim for this item
      local score_data = file_picker.get_file_score(idx)

      ---@type snacks.picker.finder.Item
      local item = {
        text = fff_item.name,
        file = fff_item.path,
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
        fff_score = score_data,
      }
      items[#items + 1] = item
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

    -- Add right-aligned score information
    if item.fff_item then
      local fff_item = item.fff_item
      local score_text = tostring(fff_item.total_frecency_score)

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
  on_close = function()
    M.state.current_file_cache = nil
  end,
  formatters = {
    file = {
      filename_first = true,
    },
  },
  live = true,
}

--- Setup the fff-snacks plugin
---@param opts? fff-snacks.Config Configuration options to customize the picker
function M.setup(opts)
  opts = opts or {}

  -- Merge custom git icons if provided
  if opts.git_icons then
    M.git_icons = vim.tbl_deep_extend("force", M.git_icons, opts.git_icons)
    opts.git_icons = nil -- Remove from opts so it doesn't get passed to snacks
  end

  if Snacks and pcall(require, "snacks.picker") then
    -- Merge user options with base source definition
    local fff_source = vim.tbl_deep_extend("force", require("fff-snacks").source, opts)
    -- Users can call Snacks.picker.fff() after this
    Snacks.picker.sources.fff = fff_source
  end

  vim.api.nvim_create_user_command("FFFSnacks", function()
    if Snacks and pcall(require, "snacks.picker") then
      -- Merge user options with base source definition
      local fff_source = vim.tbl_deep_extend("force", require("fff-snacks").source, opts)
      Snacks.picker(fff_source)
    else
      vim.notify("fff-sncaks: Snacks is not loaded", vim.log.levels.ERROR)
    end
  end, {
    desc = "Open FFF in snacks picker",
  })
end

return M
