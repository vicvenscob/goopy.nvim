local config = require("goopy.config")
local plugin_mod = require("goopy.plugin")
local git = require("goopy.git")
local state = require("goopy.state")
local lockfile = require("goopy.lockfile")
local logger = require("goopy.logger")
local events = require("goopy.events")
local paths = require("goopy.paths")

local M = {}

local function run_build(plugin)
  if plugin.build then
    local ok, err = pcall(plugin.build, plugin)
    if not ok then
      logger.error("build hook failed for '" .. plugin.name .. "': " .. tostring(err))
    end
  end
end

local function install_one(plugin, cb)
  if plugin_mod.is_installed(plugin) then
    cb(true)
    return
  end

  local dest = plugin_mod.path(plugin)
  events.emit("install:start", plugin)

  git.clone(plugin.repo, dest, { branch = plugin.branch }, function(ok, out)
    if not ok then
      logger.error("clone failed for '" .. plugin.name .. "': " .. table.concat(out, "\n"))
      state.set(plugin.name, "error")
      events.emit("install:error", plugin, out)
      cb(false)
      return
    end

    local ref = plugin.commit or plugin.tag or plugin.version
    if ref then
      git.checkout(dest, ref, function(co_ok, co_out)
        if not co_ok then
          logger.warn("checkout '" .. ref .. "' failed for '" .. plugin.name .. "'")
        end
        run_build(plugin)
        git.rev_parse(dest, "HEAD", function(commit)
          if commit then lockfile.update_entry(plugin.name, commit) end
        end)
        state.set(plugin.name, "installed")
        events.emit("install:done", plugin)
        cb(true)
      end)
    else
      run_build(plugin)
      git.rev_parse(dest, "HEAD", function(commit)
        if commit then lockfile.update_entry(plugin.name, commit) end
      end)
      state.set(plugin.name, "installed")
      events.emit("install:done", plugin)
      cb(true)
    end
  end)
end

-- install all plugins that aren't yet installed
function M.install(names)
  paths.ensure()
  local plugins = config.all()

  if names then
    local filter = {}
    for _, n in ipairs(names) do filter[n] = true end
    plugins = vim.tbl_filter(function(p) return filter[p.name] end, plugins)
  end

  local to_install = vim.tbl_filter(function(p)
    return p.enabled and not plugin_mod.is_installed(p)
  end, plugins)

  if #to_install == 0 then
    logger.info("nothing to install")
    return
  end

  for _, p in ipairs(to_install) do
    install_one(p, function() end)
  end
end

M._install_one = install_one

return M
