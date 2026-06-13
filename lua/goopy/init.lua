local config = require("goopy.config")
local plugin_mod = require("goopy.plugin")
local graph = require("goopy.graph")
local installer = require("goopy.installer")
local updater = require("goopy.updater")
local loader = require("goopy.loader")
local state = require("goopy.state")
local commands = require("goopy.commands")
local paths = require("goopy.paths")
local logger = require("goopy.logger")
local events = require("goopy.events")

local M = {}

M.config = config
M.events = events

function M.setup(opts)
  opts = opts or {}
  paths.ensure()

  if opts.log_level then
    logger.level = ({ debug = 1, info = 2, warn = 3, error = 4 })[opts.log_level] or logger.level
  end

  commands.setup()

  if opts.spec then
    for _, spec in ipairs(opts.spec) do
      M.add(spec)
    end
  end

  -- defer trigger setup to allow full config to be registered
  vim.schedule(function()
    loader.setup_triggers()
    state.refresh(config.all())
  end)
end

function M.add(spec)
  return config.add(spec)
end

-- alias
M.use = M.add

function M.remove(name)
  local p = config.get(name)
  if p then
    if p.uninstall then pcall(p.uninstall, p) end
    if plugin_mod.is_installed(p) then
      vim.fn.delete(plugin_mod.path(p), "rf")
    end
    require("goopy.lockfile").remove_entry(name)
  end
  return config.remove(name)
end

function M.install(names)
  installer.install(names)
end

function M.update(names)
  updater.update(names)
end

function M.load(name)
  loader.load(name)
end

function M.reload(name)
  loader.reload(name)
end

function M.list()
  return config.all()
end

function M.status()
  state.refresh(config.all())
  return state.status
end

-- install missing, update existing, remove plugins not in config
function M.sync()
  installer.install()
  updater.update()
  M.clean()
end

-- remove installed plugins not present in config
function M.clean()
  local configured = {}
  for _, p in ipairs(config.all()) do
    configured[p.name] = true
  end

  local dirs = vim.fn.glob(paths.pack_dir .. "/*", false, true)
  for _, dir in ipairs(dirs) do
    local name = vim.fn.fnamemodify(dir, ":t")
    if not configured[name] then
      logger.info("removing unused plugin '" .. name .. "'")
      vim.fn.delete(dir, "rf")
      require("goopy.lockfile").remove_entry(name)
    end
  end
end

return M
