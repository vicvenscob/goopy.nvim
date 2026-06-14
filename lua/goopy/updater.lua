local config = require("goopy.config")
local plugin_mod = require("goopy.plugin")
local git = require("goopy.git")
local state = require("goopy.state")
local lockfile = require("goopy.lockfile")
local logger = require("goopy.logger")
local events = require("goopy.events")

local M = {}

local function update_one(plugin, cb)
  if not plugin_mod.is_installed(plugin) then
    cb(false)
    return
  end

  -- pinned commit: nothing to update
  if plugin.commit then
    cb(true)
    return
  end

  local dest = plugin_mod.path(plugin)
  events.emit("update:start", plugin)

  git.fetch(dest, function(fok, fout)
    if not fok then
      logger.error("fetch failed for '" .. plugin.name .. "': " .. table.concat(fout, "\n"))
      cb(false)
      return
    end

    local ref = plugin.tag or plugin.version or plugin.branch
    local finish = function()
      git.rev_parse(dest, "HEAD", function(commit)
        if commit then lockfile.update_entry(plugin.name, commit) end
      end)
      if plugin.build then
        pcall(plugin.build, plugin)
      end
      events.emit("update:done", plugin)
      cb(true)
    end

    if ref then
      git.checkout(dest, ref, function() finish() end)
    else
      git.pull(dest, function(pok, pout)
        if not pok then
          logger.warn("pull failed for '" .. plugin.name .. "': " .. table.concat(pout, "\n"))
        end
        finish()
      end)
    end
  end)
end

function M.update(names)
  local plugins = config.all()

  if names then
    local filter = {}
    for _, n in ipairs(names) do filter[n] = true end
    plugins = vim.tbl_filter(function(p) return filter[p.name] end, plugins)
  end

  local to_update = vim.tbl_filter(function(p)
    return p.enabled and plugin_mod.is_installed(p)
  end, plugins)

  for _, p in ipairs(to_update) do
    update_one(p, function() end)
  end
end

M._update_one = update_one

return M
