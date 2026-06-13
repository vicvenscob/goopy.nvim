local M = {}

-- Normalize a spec table into a plugin object
-- spec can be: "owner/repo" string, or table with `repo` key (+ all other fields)
function M.normalize(spec)
  if type(spec) == "string" then
    spec = { repo = spec }
  end

  assert(spec.repo, "goopy: plugin spec requires a `repo` field")

  local repo = spec.repo
  local default_name = repo:match("([^/]+)$"):gsub("%.lua$", "")

  local plugin = {
    repo = repo,
    name = spec.name or default_name,
    dependencies = spec.dependencies or {},
    optional = spec.optional or false,
    version = spec.version,
    branch = spec.branch,
    commit = spec.commit,
    tag = spec.tag,
    priority = spec.priority or 50,
    enabled = spec.enabled,

    -- loading
    event = spec.event,
    cmd = spec.cmd,
    ft = spec.ft,
    keys = spec.keys,
    module = spec.module,
    startup = spec.startup or false,
    manual = spec.manual or false,

    -- hooks
    init = spec.init,
    config = spec.config,
    build = spec.build,
    uninstall = spec.uninstall,

    -- runtime state (filled in by goopy)
    _loaded = false,
    _installed = nil, -- determined at runtime
  }

  if plugin.enabled == nil then
    plugin.enabled = true
  elseif type(plugin.enabled) == "function" then
    plugin.enabled = plugin.enabled()
  end

  -- if no loading trigger is specified and not manual, default to startup
  if not (plugin.event or plugin.cmd or plugin.ft or plugin.keys or plugin.module or plugin.manual) then
    plugin.startup = true
  end

  return plugin
end

function M.path(plugin)
  return require("goopy.paths").plugin_path(plugin.name)
end

function M.is_installed(plugin)
  return vim.fn.isdirectory(M.path(plugin)) == 1
end

return M
