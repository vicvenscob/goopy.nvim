local plugin_mod = require("goopy.plugin")

local M = {}

M.status = {} -- name -> "installed" | "not_installed" | "loaded" | "error"

function M.refresh(plugins)
  for _, p in ipairs(plugins) do
    if plugin_mod.is_installed(p) then
      M.status[p.name] = p._loaded and "loaded" or "installed"
    else
      M.status[p.name] = "not_installed"
    end
  end
end

function M.set(name, status)
  M.status[name] = status
end

function M.get(name)
  return M.status[name] or "unknown"
end

return M
