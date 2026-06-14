local M = {}

-- topological sort by dependencies, then by priority
function M.resolve(plugins)
  local by_name = {}
  for _, p in ipairs(plugins) do by_name[p.name] = p end

  local visited, visiting, order = {}, {}, {}

  local function visit(name)
    if visited[name] then return end
    if visiting[name] then
      error("goopy: dependency cycle detected at '" .. name .. "'")
    end
    visiting[name] = true

    local p = by_name[name]
    if p then
      for _, dep in ipairs(p.dependencies) do
        visit(dep)
      end
    end

    visiting[name] = nil
    visited[name] = true
    table.insert(order, name)
  end

  -- stable order: iterate input order, but respect priority as tiebreaker
  local sorted = vim.deepcopy(plugins)
  table.sort(sorted, function(a, b) return a.priority > b.priority end)

  for _, p in ipairs(sorted) do
    visit(p.name)
  end

  local result = {}
  for _, name in ipairs(order) do
    if by_name[name] then
      table.insert(result, by_name[name])
    end
  end

  return result
end

-- get dependents of a plugin (reverse edges)
function M.dependents(plugins, name)
  local deps = {}
  for _, p in ipairs(plugins) do
    for _, dep in ipairs(p.dependencies) do
      if dep == name then table.insert(deps, p.name) end
    end
  end
  return deps
end

return M
