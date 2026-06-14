local plugin_mod = require("goopy.plugin")

local M = {}

M.plugins = {} -- name -> plugin object
M.order = {}   -- insertion order of names

function M.add(spec)
  local plugin = plugin_mod.normalize(spec)

  if M.plugins[plugin.name] then
    require("goopy.logger").warn("plugin '" .. plugin.name .. "' redefined, overwriting")
  else
    table.insert(M.order, plugin.name)
  end

  M.plugins[plugin.name] = plugin

  -- normalize dependency specs too
  for i, dep in ipairs(plugin.dependencies) do
    if type(dep) ~= "string" then
      local dep_plugin = plugin_mod.normalize(dep)
      M.plugins[dep_plugin.name] = M.plugins[dep_plugin.name] or dep_plugin
      if not vim.tbl_contains(M.order, dep_plugin.name) then
        table.insert(M.order, dep_plugin.name)
      end
      plugin.dependencies[i] = dep_plugin.name
    end
  end

  return plugin
end

function M.remove(name)
  if M.plugins[name] then
    M.plugins[name] = nil
    for i, n in ipairs(M.order) do
      if n == name then table.remove(M.order, i) break end
    end
    return true
  end
  return false
end

function M.get(name)
  return M.plugins[name]
end

function M.all()
  local list = {}
  for _, name in ipairs(M.order) do
    table.insert(list, M.plugins[name])
  end
  return list
end

return M
