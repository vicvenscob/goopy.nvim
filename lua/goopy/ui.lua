local config = require("goopy.config")
local state = require("goopy.state")
local plugin_mod = require("goopy.plugin")

local M = {}

local icons = {
  loaded = "●",
  installed = "○",
  not_installed = "✗",
  error = "!",
}

function M.status()
  state.refresh(config.all())

  local lines = { "Goopy Status", "" }
  for _, p in ipairs(config.all()) do
    local s = state.get(p.name)
    local icon = icons[s] or "?"
    table.insert(lines, string.format("  %s %-30s %s", icon, p.name, s))
  end

  M.show_float(lines)
end

function M.list()
  local lines = { "Goopy Plugins", "" }
  for _, p in ipairs(config.all()) do
    table.insert(lines, string.format("  %-30s %s", p.name, p.repo))
  end
  M.show_float(lines)
end

function M.log(n)
  local paths = require("goopy.paths")
  n = n or 100
  local lines = vim.fn.readfile(paths.log_file)
  local total = #lines
  local from = math.max(1, total - n + 1)
  M.show_float(vim.list_slice(lines, from, total))
end

function M.show_float(lines)
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
  vim.bo[buf].modifiable = false
  vim.bo[buf].filetype = "goopy"

  local width = math.min(80, vim.o.columns - 4)
  local height = math.min(#lines + 2, vim.o.lines - 4)

  vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = (vim.o.columns - width) / 2,
    row = (vim.o.lines - height) / 2,
    style = "minimal",
    border = "rounded",
    title = " goopy ",
    title_pos = "center",
  })

  vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = buf })
  vim.keymap.set("n", "<esc>", "<cmd>close<cr>", { buffer = buf })
end

return M
