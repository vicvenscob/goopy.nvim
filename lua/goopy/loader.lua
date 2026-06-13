local config = require("goopy.config")
local plugin_mod = require("goopy.plugin")
local graph = require("goopy.graph")
local state = require("goopy.state")
local events = require("goopy.events")
local logger = require("goopy.logger")

local M = {}

local function do_load(plugin)
  if plugin._loaded then return end
  if not plugin_mod.is_installed(plugin) then
    logger.warn("plugin '" .. plugin.name .. "' not installed, skipping load")
    return
  end

  -- load dependencies first
  for _, dep_name in ipairs(plugin.dependencies) do
    local dep = config.get(dep_name)
    if dep then do_load(dep) end
  end

  events.emit("load:start", plugin)

  if plugin.init then
    pcall(plugin.init, plugin)
  end

  vim.cmd("packadd " .. plugin.name)

  if plugin.config then
    local ok, err = pcall(plugin.config, plugin)
    if not ok then
      logger.error("config hook failed for '" .. plugin.name .. "': " .. tostring(err))
    end
  end

  plugin._loaded = true
  state.set(plugin.name, "loaded")
  events.emit("load:done", plugin)
end

function M.load(name)
  local plugin = config.get(name)
  if not plugin then
    logger.error("unknown plugin '" .. name .. "'")
    return
  end
  do_load(plugin)
end

function M.reload(name)
  local plugin = config.get(name)
  if not plugin then
    logger.error("unknown plugin '" .. name .. "'")
    return
  end

  plugin._loaded = false

  -- clear loaded lua modules belonging to this plugin
  if plugin.module then
    for mod_name in pairs(package.loaded) do
      if mod_name == plugin.module or mod_name:match("^" .. plugin.module .. "%.") then
        package.loaded[mod_name] = nil
      end
    end
  end

  do_load(plugin)
end

-- setup autocommands/usercmds for lazy-loading triggers
function M.setup_triggers()
  local plugins = config.all()

  for _, p in ipairs(plugins) do
    if not p.enabled then goto continue end

    if p.startup then
      do_load(p)
    end

    if p.event then
      local events_list = type(p.event) == "table" and p.event or { p.event }
      vim.api.nvim_create_autocmd(events_list, {
        once = true,
        callback = function() do_load(p) end,
      })
    end

    if p.ft then
      local fts = type(p.ft) == "table" and p.ft or { p.ft }
      vim.api.nvim_create_autocmd("FileType", {
        pattern = fts,
        once = true,
        callback = function() do_load(p) end,
      })
    end

    if p.cmd then
      local cmds = type(p.cmd) == "table" and p.cmd or { p.cmd }
      for _, cmd_name in ipairs(cmds) do
        vim.api.nvim_create_user_command(cmd_name, function(opts)
          do_load(p)
          vim.cmd(cmd_name .. " " .. (opts.args or ""))
        end, { nargs = "*", bang = true })
      end
    end

    if p.keys then
      local keys_list = type(p.keys) == "table" and p.keys or { p.keys }
      for _, key in ipairs(keys_list) do
        local lhs, mode = key, "n"
        if type(key) == "table" then
          lhs, mode = key[1], key.mode or "n"
        end
        vim.keymap.set(mode, lhs, function()
          do_load(p)
          vim.api.nvim_input(lhs)
        end, { noremap = true })
      end
    end

    if p.module then
      -- hook require() for lazy module loading
      local orig_require = require
      _G.require = function(mod_name)
        if mod_name == p.module or mod_name:match("^" .. p.module .. "%.") then
          do_load(p)
        end
        return orig_require(mod_name)
      end
    end

    ::continue::
  end
end

return M
